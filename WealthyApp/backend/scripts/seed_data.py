"""
scripts/seed_dev.py
-------------------
Skrypt seedujący bazę danych danymi testowymi dla FinApp.

Uruchomienie (z katalogu backend/):
    python scripts/seed_dev.py

UWAGA: Skrypt jest idempotentny — sprawdza czy user już istnieje
i przerywa jeśli tak, żeby nie duplikować danych.
"""

import sys
import os

# Dodajemy katalog backend/ do ścieżki — skrypt może być w scripts/
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, date, timezone, timedelta
from database import SessionLocal
from models.user import User
from models.asset import Asset
from models.saving_account import SavingsAccount
from models.ppk_account import PPKAccount
from models.ike_ikze_account import IKEAccount
from models.crypto_wallet import CryptoWallet
from models.holding import Holding
from models.bond_details import BondDetails
from models.cfd_details import CFDDetails
from models.category import Category
from models.transaction import Transaction

# Auth service — do hashowania hasła
from services.auth_service import hash_password

from enums import AssetClass, CFDDirection, IkeIkzeType, ExpenseIncome

# ------------------------------------------------------------------ #
#  Konfiguracja seed                                                  #
# ------------------------------------------------------------------ #

SEED_EMAIL = "test@finapp.pl"
SEED_PASSWORD = "Test1234!"
SEED_FULL_NAME = "Jan Kowalski (seed)"

now = datetime.now(timezone.utc)
today = date.today()


def run_seed():
    db = SessionLocal()
    try:
        # ── Idempotencja ─────────────────────────────────────────────
        existing = db.query(User).filter(User.email == SEED_EMAIL).first()
        if existing:
            print(f"[seed] User '{SEED_EMAIL}' już istnieje — przerywam. "
                  f"Usuń bazę lub zmień SEED_EMAIL żeby zresetować.")
            return

        print("[seed] Tworzę dane testowe...")

        # ═══════════════════════════════════════════════════════════ #
        #  1. USER                                                    #
        # ═══════════════════════════════════════════════════════════ #
        user = User(
            email=SEED_EMAIL,
            hashed_password=hash_password(SEED_PASSWORD),
            full_name=SEED_FULL_NAME,
            created_at=now,
            updated_at=now,
        )
        db.add(user)
        db.flush()  # flush żeby user.id było dostępne przed commitem
        print(f"[seed] User: id={user.id}, email={user.email}")

        # ═══════════════════════════════════════════════════════════ #
        #  2. SAVINGS ACCOUNT (PLN)                                   #
        #  JTI: najpierw Asset, potem SavingsAccount z asset_id      #
        # ═══════════════════════════════════════════════════════════ #
        asset_savings = Asset(
            user_id=user.id,
            asset_type="savings",
            name="PKO Konto Oszczędnościowe",
            currency="PLN",
            created_at=now,
            updated_at=now,
        )
        db.add(asset_savings)
        db.flush()

        savings = SavingsAccount(
            asset_id=asset_savings.id,
            institution_name="PKO Bank Polski",
            interest_rate=5.5,
            current_balance=25000.00,
            balance_synced_at=now,
        )
        db.add(savings)
        print(f"[seed] SavingsAccount: {savings.institution_name}, balance=25000 PLN")

        # ═══════════════════════════════════════════════════════════ #
        #  3. PPK ACCOUNT                                             #
        # ═══════════════════════════════════════════════════════════ #
        asset_ppk = Asset(
            user_id=user.id,
            asset_type="ppk",
            name="PPK - Santander TFI",
            currency="PLN",
            created_at=now,
            updated_at=now,
        )
        db.add(asset_ppk)
        db.flush()

        ppk = PPKAccount(
            asset_id=asset_ppk.id,
            institution_name="Santander TFI",
            fund_name="Santander PPK 2055",
            employee_rate=2.0,
            employer_rate=1.5,
            current_value=8750.00,
            value_updated_at=now,
        )
        db.add(ppk)
        print(f"[seed] PPKAccount: {ppk.institution_name}, value=8750 PLN")

        # ═══════════════════════════════════════════════════════════ #
        #  4. IKE ACCOUNT + holdings w USD i PLN                     #
        # ═══════════════════════════════════════════════════════════ #
        asset_ike = Asset(
            user_id=user.id,
            asset_type="ike",
            name="IKE - XTB",
            currency="PLN",
            created_at=now,
            updated_at=now,
        )
        db.add(asset_ike)
        db.flush()

        ike = IKEAccount(
            asset_id=asset_ike.id,
            institution_name="XTB",
            account_subtype=IkeIkzeType.IKE,      # ← było: account_type="IKE"
            annual_limit=23472.0,
            annual_contributed=18000.0,            # ← było: annual_contributions
            cash_balance=2500.00,
            balance_synced_at=now,
        )
        db.add(ike)
        db.flush()
        print(f"[seed] IKEAccount: {ike.institution_name}, cash=2500 PLN")

        # Holding IKE — AAPL w USD (testuje wielowalutowość)
        holding_aapl = Holding(
            user_id=user.id,
            ike_account_id=ike.asset_id,
            ticker="AAPL",
            name="Apple Inc.",
            asset_class=AssetClass.STOCK,
            quantity=10.0,
            avg_purchase_price=165.0,   # USD — cena zakupu
            currency="USD",
            current_price=189.5,        # USD — zostanie nadpisane przez price_updater
            entry_date=now,
            last_price_update=now,
        )
        db.add(holding_aapl)

        # Holding IKE — CDR.WA w PLN (polska spółka)
        holding_cdr = Holding(
            user_id=user.id,
            ike_account_id=ike.asset_id,
            ticker="CDR.WA",
            name="CD Projekt S.A.",
            asset_class=AssetClass.STOCK,
            quantity=50.0,
            avg_purchase_price=120.0,   # PLN
            currency="PLN",
            current_price=155.0,        # PLN
            entry_date=now,
            last_price_update=now,
        )
        db.add(holding_cdr)
        print(f"[seed] Holdings IKE: AAPL (USD), CDR.WA (PLN)")

        # ═══════════════════════════════════════════════════════════ #
        #  5. CRYPTO WALLET                                           #
        # ═══════════════════════════════════════════════════════════ #
        asset_crypto = Asset(
            user_id=user.id,
            asset_type="crypto",
            name="Portfel Crypto - Binance",
            currency="USD",
            created_at=now,
            updated_at=now,
        )
        db.add(asset_crypto)
        db.flush()

        crypto = CryptoWallet(
            asset_id=asset_crypto.id,
            institution_name="Binance",
            wallet_address="seed-placeholder",   # ← było: None
            current_value=12500.00,
            value_updated_at=now,
        )
        db.add(crypto)
        print(f"[seed] CryptoWallet: Binance, value=12500")

        # ═══════════════════════════════════════════════════════════ #
        #  6. STANDALONE HOLDINGS (poza IKE) — różne klasy aktywów   #
        # ═══════════════════════════════════════════════════════════ #

        # ETF w EUR
        holding_etf = Holding(
            user_id=user.id,
            ike_account_id=None,
            ticker="VWCE.DE",
            name="Vanguard FTSE All-World UCITS ETF",
            asset_class=AssetClass.ETF,
            quantity=25.0,
            avg_purchase_price=95.0,    # EUR
            currency="EUR",
            current_price=112.0,        # EUR
            entry_date=now,
            last_price_update=now,
        )
        db.add(holding_etf)

        # Obligacja skarbowa (PLN)
        holding_bond = Holding(
            user_id=user.id,
            ike_account_id=None,
            ticker="DS1030",
            name="Obligacja Skarbowa DS1030",
            asset_class=AssetClass.BOND,
            quantity=10.0,
            avg_purchase_price=1000.0,  # PLN — wartość nominalna
            currency="PLN",
            current_price=1020.0,
            entry_date=now,
            last_price_update=now,
        )
        db.add(holding_bond)
        db.flush()

        bond_details = BondDetails(
            holding_id=holding_bond.id,
            face_value=1000.0,
            coupon_rate=5.75,
            maturity_date=datetime(2030, 10, 25),
            issuer="Skarb Państwa",
        )
        db.add(bond_details)

        # CFD — EURUSD long
        holding_cfd = Holding(
            user_id=user.id,
            ike_account_id=None,
            ticker="EURUSD",
            name="EUR/USD CFD",
            asset_class=AssetClass.CFD,
            quantity=1.0,
            avg_purchase_price=1.085,
            currency="USD",
            current_price=1.092,
            entry_date=now,
            last_price_update=now,
        )
        db.add(holding_cfd)
        db.flush()

        cfd_details = CFDDetails(
            holding_id=holding_cfd.id,
            leverage=10.0,
            margin_used=500.0,
            direction=CFDDirection.LONG,
        )
        db.add(cfd_details)

        # Crypto holding (BTC-USD)
        holding_btc = Holding(
            user_id=user.id,
            ike_account_id=None,
            ticker="BTC-USD",
            name="Bitcoin",
            asset_class=AssetClass.CRYPTO,
            quantity=0.15,
            avg_purchase_price=45000.0,  # USD
            currency="USD",
            current_price=62000.0,
            entry_date=now,
            last_price_update=now,
        )
        db.add(holding_btc)
        print(f"[seed] Standalone holdings: VWCE.DE (EUR), DS1030 (PLN), EURUSD CFD, BTC-USD")

        # ═══════════════════════════════════════════════════════════ #
        #  7. CATEGORIES                                              #
        # ═══════════════════════════════════════════════════════════ #
        categories_data = [
            # Systemowe (is_default=True, user_id=None)
            ("Jedzenie", "expense", "🍔", "#FF6B6B", True),
            ("Transport", "expense", "🚗", "#4ECDC4", True),
            ("Rozrywka", "expense", "🎬", "#45B7D1", True),
            ("Zdrowie", "expense", "💊", "#96CEB4", True),
            ("Mieszkanie", "expense", "🏠", "#FFEAA7", True),
            ("Wynagrodzenie", "income", "💰", "#6BCB77", True),
            ("Dywidenda", "income", "📈", "#4D96FF", True),
        ]

        categories = {}
        for name, tx_type, icon, color, is_default in categories_data:
            cat = Category(
                user_id=None if is_default else user.id,
                name=name,
                transaction_type=tx_type,
                icon=icon,
                color=color,
                is_default=is_default,
                created_at=now,
            )
            db.add(cat)
            db.flush()
            categories[name] = cat

        print(f"[seed] Categories: {len(categories_data)} kategorii")

        # ═══════════════════════════════════════════════════════════ #
        #  8. TRANSACTIONS — bieżący miesiąc                         #
        # ═══════════════════════════════════════════════════════════ #
        month_start = today.replace(day=1)

        transactions_data = [
            # (type, amount, category_name, days_ago, description)
            ("income",  8500.0,  "Wynagrodzenie", 20, "Pensja - maj 2025"),
            ("income",  450.0,   "Dywidenda",      15, "Dywidenda AAPL"),
            ("expense", 1200.0,  "Mieszkanie",     18, "Czynsz maj"),
            ("expense", 380.0,   "Jedzenie",       14, "Zakupy spożywcze"),
            ("expense", 220.0,   "Jedzenie",        7, "Restauracje"),
            ("expense", 150.0,   "Transport",      10, "Paliwo + parking"),
            ("expense", 89.0,    "Rozrywka",        5, "Netflix + Spotify"),
            ("expense", 320.0,   "Zdrowie",         3, "Dentysta"),
            ("expense", 55.0,    "Transport",       1, "Bilet miesięczny"),
            ("expense", 180.0,   "Jedzenie",        0, "Weekendowe zakupy"),
        ]

        for tx_type, amount, cat_name, days_ago, desc in transactions_data:
            tx_date = today - timedelta(days=days_ago)
            # Upewniamy się że transakcja jest w bieżącym miesiącu
            if tx_date < month_start:
                tx_date = month_start

            tx = Transaction(
                user_id=user.id,
                category_id=categories[cat_name].id,
                transaction_type=ExpenseIncome.EXPENSE if tx_type == "expense" else ExpenseIncome.INCOME,  # ← było: type=tx_type
                amount=amount,
                currency="PLN",
                transaction_date=tx_date,
                description=desc,
                created_at=now,
                updated_at=now,
            )
            db.add(tx)

        print(f"[seed] Transactions: {len(transactions_data)} transakcji w bieżącym miesiącu")

        # ═══════════════════════════════════════════════════════════ #
        #  COMMIT                                                     #
        # ═══════════════════════════════════════════════════════════ #
        db.commit()
        print("\n[seed] ✓ Wszystkie dane zostały zapisane pomyślnie!")
        print(f"\n  Login:    {SEED_EMAIL}")
        print(f"  Hasło:    {SEED_PASSWORD}")
        print(f"\n  Zasoby seedowane:")
        print(f"  - 1x SavingsAccount (PKO, 25 000 PLN)")
        print(f"  - 1x PPKAccount (Santander, 8 750 PLN)")
        print(f"  - 1x IKEAccount (XTB) + 2 holdings: AAPL(USD), CDR.WA(PLN)")
        print(f"  - 1x CryptoWallet (Binance)")
        print(f"  - 4x standalone holdings: VWCE.DE(EUR), DS1030(PLN), EURUSD CFD, BTC-USD(USD)")
        print(f"  - 7x categories (systemowe)")
        print(f"  - 10x transactions (bieżący miesiąc)")

    except Exception as e:
        db.rollback()
        print(f"[seed] ✗ Błąd: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()


if __name__ == "__main__":
    run_seed()