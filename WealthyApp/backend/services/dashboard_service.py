from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, date
from typing import Optional

# Modele — dostosuj ścieżki do swojej struktury
from models.holding import Holding
from models.saving_account import SavingsAccount
from models.ppk_account import PPKAccount
from models.ike_ikze_account import IKEAccount
from models.crypto_wallet import CryptoWallet
from models.transaction import Transaction
from models.category import Category
from models.asset import Asset

from enums import ExpenseIncome

import logging
logger = logging.getLogger(__name__)

from schemas.dashboard import (
    DashboardSummaryResponse,
    AssetBreakdownItem,
    TopExpenseCategory,
    AlertItem,
)


def get_dashboard_summary(db: Session, user_id: int) -> DashboardSummaryResponse:
    """Główna funkcja agregująca wszystkie dane dashboardu."""

    # Pobieramy kursy raz — przekażemy do funkcji które tego potrzebują
    fx_rates = _get_fx_rates(db)

    # Zbieramy każdy składnik osobno — czytelniej niż jeden mega-query
    savings_value = _get_savings_value(db, user_id)
    ppk_value = _get_ppk_value(db, user_id)
    ike_value, ike_alerts = _get_ike_value_and_alerts(db, user_id, fx_rates)
    crypto_value = _get_crypto_value(db, user_id)
    holdings_value, holdings_pl, prices_last_updated, price_alerts = _get_holdings_data(db, user_id, fx_rates)
    
    total_assets_value = savings_value + ppk_value + ike_value + crypto_value + holdings_value

    # Breakdown per typ — wartości już mamy, liczymy tylko %
    assets_breakdown = _build_breakdown(
        total=total_assets_value,
        savings=savings_value,
        ppk=ppk_value,
        ike_ikze=ike_value,
        crypto=crypto_value,
        holdings=holdings_value,
    )

    # Transakcje miesięczne
    monthly_income, monthly_expense = _get_monthly_flows(db, user_id)
    top_categories = _get_top_expense_categories(db, user_id)

    # Zbieramy alerty ze wszystkich źródeł
    alerts = ike_alerts + price_alerts

    return DashboardSummaryResponse(
        total_assets_value=round(total_assets_value, 2),
        total_holdings_value=round(holdings_value, 2),
        total_holdings_pl=round(holdings_pl, 2),
        monthly_income=round(monthly_income, 2),
        monthly_expense=round(monthly_expense, 2),
        monthly_balance=round(monthly_income - monthly_expense, 2),
        assets_breakdown=assets_breakdown,
        top_expense_categories=top_categories,
        alerts=alerts,
        prices_last_updated=prices_last_updated,
    )


# --- Funkcje pomocnicze (prywatne — prefix _) ---

def _get_savings_value(db: Session, user_id: int) -> float:
    result = db.query(func.sum(SavingsAccount.current_balance))\
               .join(Asset, Asset.id == SavingsAccount.asset_id)\
               .filter(Asset.user_id == user_id)\
               .scalar()
    return float(result or 0)


def _get_ppk_value(db: Session, user_id: int) -> float:
    result = db.query(func.sum(PPKAccount.current_value))\
               .join(Asset, Asset.id == PPKAccount.asset_id)\
               .filter(Asset.user_id == user_id)\
               .scalar()
    return float(result or 0)


def _get_ike_value_and_alerts(
    db: Session, user_id: int, fx_rates: dict[str, float]  # ← dodane
) -> tuple[float, list[AlertItem]]:
    """
    IKE/IKZE = cash_balance + SUM(holding.quantity × holding.current_price)
    dla holdings powiązanych z tym kontem.
    Przy okazji sprawdzamy przekroczenie annual_limit.
    """
    accounts = db.query(IKEAccount)\
             .join(Asset, Asset.id == IKEAccount.asset_id)\
             .filter(Asset.user_id == user_id)\
             .all()
    total = 0.0
    alerts = []

    for acc in accounts:
        cash = float(acc.cash_balance or 0)
        holdings = db.query(Holding).filter(Holding.ike_account_id == acc.asset_id).all()
        holdings_val = sum(
            float(h.quantity or 0) * _to_pln(float(h.current_price or 0), h.currency or "PLN", fx_rates)
            for h in holdings
        )

        acc_value = cash + holdings_val
        total += acc_value

        # Alert: przekroczenie limitu rocznego
        if acc.annual_limit and acc.annual_contributed and \
            acc.annual_contributed >= acc.annual_limit:
                alerts.append(AlertItem(
                    alert_type="ike_limit_exceeded",
                    message=f"Konto {acc.account_subtype} osiągnęło limit roczny "  # było: acc.account_type
                            f"({acc.annual_contributed:.0f} / {acc.annual_limit:.0f} PLN)",
                    severity="warning",
                ))

    return total, alerts


def _get_crypto_value(db: Session, user_id: int) -> float:
    """
    Zakładam że CryptoWallet ma pole current_value lub
    liczymy przez holdings powiązane z walletem.
    Dostosuj do swojego modelu.
    """
    result = db.query(func.sum(CryptoWallet.current_value))\
               .join(Asset, Asset.id == CryptoWallet.asset_id)\
               .filter(Asset.user_id == user_id)\
               .scalar()
    return float(result or 0)


def _get_holdings_data(
    db: Session, user_id: int, fx_rates: dict[str, float]
) -> tuple[float, float, Optional[datetime], list[AlertItem]]:

    from datetime import timezone

    holdings = db.query(Holding).filter(Holding.user_id == user_id).all()

    total_value = 0.0
    total_pl = 0.0
    last_updated_times = []
    alerts = []

    for h in holdings:
        qty = float(h.quantity or 0)
        current = float(h.current_price or 0)
        avg = float(h.avg_purchase_price or 0)
        currency = h.currency or "PLN"  # fallback jeśli pole puste

        # Przeliczamy na PLN przed agregacją
        current_pln = _to_pln(current, currency, fx_rates)
        avg_pln = _to_pln(avg, currency, fx_rates)

        total_value += qty * current_pln

        if avg_pln > 0:
            total_pl += (current_pln - avg_pln) * qty

        if h.last_price_update:
            last_updated_times.append(h.last_price_update)

    prices_last_updated = max(last_updated_times) if last_updated_times else None

    if prices_last_updated:
        age = datetime.now(timezone.utc) - prices_last_updated.replace(tzinfo=timezone.utc)
        if age.total_seconds() > 86400:
            alerts.append(AlertItem(
                alert_type="stale_prices",
                message=f"Ceny holdings nie były aktualizowane od ponad 24h "
                        f"(ostatnio: {prices_last_updated.strftime('%Y-%m-%d %H:%M')})",
                severity="warning",
            ))

    return total_value, total_pl, prices_last_updated, alerts


def _get_monthly_flows(db: Session, user_id: int) -> tuple[float, float]:
    today = date.today()
    month_start = today.replace(day=1)

    results = (
        db.query(Transaction.transaction_type, func.sum(Transaction.amount))
        .filter(
            Transaction.user_id == user_id,
            Transaction.transaction_date >= month_start,
        )
        .group_by(Transaction.transaction_type)
        .all()
    )

    income = 0.0
    expense = 0.0

    for tx_type, total in results:
        if tx_type == ExpenseIncome.INCOME:
            income = float(total or 0)
        elif tx_type == ExpenseIncome.EXPENSE:
            expense = float(total or 0)

    return income, expense


def _get_top_expense_categories(db: Session, user_id: int, limit: int = 5) -> list[TopExpenseCategory]:
    """Top N kategorii wydatków w bieżącym miesiącu z % udziałem."""
    today = date.today()
    month_start = today.replace(day=1)

    rows = (
        db.query(Category.name, func.sum(Transaction.amount).label("total"))
        .join(Transaction, Transaction.category_id == Category.id)
        .filter(
            Transaction.user_id == user_id,
            Transaction.transaction_type == ExpenseIncome.EXPENSE,  # ← było: Transaction.type == "expense"
            Transaction.transaction_date >= month_start,
        )
        .group_by(Category.name)
        .order_by(func.sum(Transaction.amount).desc())
        .limit(limit)
        .all()
    )

    if not rows:
        return []

    grand_total = sum(float(r.total) for r in rows)

    return [
        TopExpenseCategory(
            category_name=r.name,
            total_amount=round(float(r.total), 2),
            percentage=round(float(r.total) / grand_total * 100, 1) if grand_total > 0 else 0,
        )
        for r in rows
    ]


def _build_breakdown(
    total: float,
    savings: float,
    ppk: float,
    ike_ikze: float,
    crypto: float,
    holdings: float,
) -> list[AssetBreakdownItem]:
    """Buduje listę breakdown per typ aktywu z % udziałem."""
    items = [
        ("savings", savings),
        ("ppk", ppk),
        ("ike_ikze", ike_ikze),
        ("crypto", crypto),
        ("holdings", holdings),
    ]

    return [
        AssetBreakdownItem(
            asset_type=name,
            value=round(value, 2),
            # Jeśli total = 0 (pusty portfel), zwracamy 0% zamiast dzielić przez 0
            percentage=round(value / total * 100, 1) if total > 0 else 0,
        )
        for name, value in items
        if value > 0  # pomijamy typy z wartością 0 — czystszy wykres
    ]

def _get_fx_rates(db: Session) -> dict[str, float]:
    """
    Czyta kursy z tabeli exchange_rates i zwraca słownik {"USD": 3.92, ...}.
    PLN zawsze = 1.0 — nie trzymamy w bazie, dodajemy tutaj.
    """
    from models.exchange_rate import ExchangeRate

    rows = db.query(ExchangeRate).all()
    rates = {row.from_currency: row.rate for row in rows}
    rates["PLN"] = 1.0  # PLN → PLN, zawsze
    return rates


def _to_pln(value: float, currency: str, rates: dict[str, float]) -> float:
    """
    Przelicza wartość z danej waluty na PLN.
    Jeśli waluta nieznana (brak kursu w bazie) — zwraca 0.0 i loguje warning.
    Zasada: better stale than wrong — nie zgadujemy kursu.
    """
    if currency == "PLN":
        return value
    rate = rates.get(currency)
    if rate is None:
        logger.warning(f"Brak kursu dla waluty {currency} — wartość pominięta w agregacji.")
        return 0.0
    return value * rate