from pydantic import BaseModel
from datetime import datetime
from typing import Optional


# --- Elementy składowe ---

class AssetBreakdownItem(BaseModel):
    """Jeden wiersz w breakdown per typ aktywu (np. 'Krypto', 'Holdings')."""
    asset_type: str          # np. "savings", "crypto", "holdings", "ppk", "ike_ikze"
    value: float             # łączna wartość w PLN
    percentage: float        # % całego portfela — Flutter użyje tego do wykresu kołowego


class TopExpenseCategory(BaseModel):
    """Top 5 kategorii wydatków w bieżącym miesiącu."""
    category_name: str
    total_amount: float
    percentage: float        # % wszystkich wydatków miesiąca


class AlertItem(BaseModel):
    """Pojedynczy alert dla użytkownika."""
    alert_type: str          # np. "ike_limit_exceeded", "stale_prices"
    message: str             # czytelny tekst dla Flutter UI
    severity: str            # "warning" | "error" | "info"


# --- Główna odpowiedź ---

class DashboardSummaryResponse(BaseModel):
    # Wartości portfela
    total_assets_value: float
    total_holdings_value: float
    total_holdings_pl: float         # P&L kwotowy (może być ujemny)

    # Miesięczne przepływy
    monthly_income: float
    monthly_expense: float
    monthly_balance: float           # income - expense

    # Listy dla wykresów
    assets_breakdown: list[AssetBreakdownItem]
    top_expense_categories: list[TopExpenseCategory]

    # Alerty
    alerts: list[AlertItem]

    # Metadane świeżości cen — Flutter wyświetli "dane sprzed X minut"
    prices_last_updated: Optional[datetime] = None