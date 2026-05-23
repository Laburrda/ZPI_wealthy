"""
mock_data.py — generator danych testowych dla FinApp.

Tworzy 1 demo użytkownika z kompletnym, realistycznym portfelem finansowym.
Wszystkie operacje przechodzą przez nasze serwisy — gwarantowana spójność
z logiką produkcyjną (atomowe transakcje JTI, walidacja Pydantic, bcrypt).

Użycie:
    cd WealthyApp/backend
    python mock_data.py

Idempotentność:
    Jeśli demo user już istnieje, skrypt go usuwa (CASCADE zabiera wszystko
    powiązane: aktywa, holdings, bond/cfd_details) i tworzy od nowa.
    Inni użytkownicy (jeśli są w bazie) pozostają nietknięci.

Dane logowania demo:
    Email:    demo@finapp.com
    Hasło:    demo123
"""

from datetime import datetime

from sqlalchemy.orm import Session

from database import SessionLocal
from models.user import User
from services.auth_service import hash_password
from services import (
    savings_service,
    ppk_service,
    ike_ikze_service,
    crypto_service,
    holding_service,
)
from schemas.asset import (
    SavingsAccountCreate,
    PPKAccountCreate,
    IKEAccountCreate,
    IKZEAccountCreate,
    CryptoWalletCreate,
)
from schemas.holding import (
    StockCreate,
    ETFCreate,
    BondCreate,
    CryptoCreate,
)


# === KONFIGURACJA DEMO USERA ===
DEMO_EMAIL = "demo@finapp.com"
DEMO_PASSWORD = "demo123"
DEMO_NAME = "Demo Użytkownik"


def clean_existing_demo(db: Session) -> None:
    """Jeśli demo user istnieje, kasujemy go w całości.
    CASCADE w bazie zabiera wszystkie aktywa, holdings i tabele rozszerzające."""
    existing = db.query(User).filter(User.email == DEMO_EMAIL).first()
    if existing:
        print(f"⚠️  Demo user już istnieje (id={existing.id}). Kasuję wraz z danymi...")
        db.delete(existing)
        db.commit()
        print("   ✓ Usunięto demo usera i wszystko powiązane (CASCADE)")


def create_demo_user(db: Session) -> User:
    """Tworzy demo usera. Hasło hashowane przez bcrypt - tę samą funkcję
    co /auth/register, więc /auth/login zadziała poprawnie."""
    user = User(
        email=DEMO_EMAIL,
        hashed_password=hash_password(DEMO_PASSWORD),
        full_name=DEMO_NAME,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    print(f"\n✓ Utworzono demo usera: id={user.id}, email={user.email}")
    return user


# =========================================================
# SEEDERY POSZCZEGÓLNYCH TYPÓW AKTYWÓW
# =========================================================

def seed_savings(db: Session, user_id: int) -> None:
    """Dwa konta oszczędnościowe — typowy profil polskiego inwestora."""
    accounts = [
        SavingsAccountCreate(
            name="PKO Konto Oszczędnościowe Plus",
            currency="PLN",
            institution_name="PKO BP",
            interest_rate=5.5,
            current_balance=15000.0,
        ),
        SavingsAccountCreate(
            name="mBank eMax Plus",
            currency="PLN",
            institution_name="mBank",
            interest_rate=4.0,
            current_balance=8500.0,
        ),
    ]
    for data in accounts:
        result = savings_service.create_savings_account(db, user_id=user_id, data=data)
        print(f"   ✓ Savings: {result.asset.name} — {result.current_balance:,.2f} PLN @ {result.interest_rate}%")


def seed_ppk(db: Session, user_id: int) -> None:
    """Jeden PPK — typowy fundusz 'target date 20 lat do emerytury'."""
    data = PPKAccountCreate(
        name="Mój PPK",
        currency="PLN",
        institution_name="PKO TFI",
        fund_name="PKO Emerytura 2055",
        employee_rate=2.0,
        employer_rate=1.5,
        current_value=12000.0,
    )
    result = ppk_service.create_ppk_account(db, user_id=user_id, data=data)
    print(f"   ✓ PPK: {result.fund_name} — {result.current_value:,.2f} PLN")


def seed_ike(db: Session, user_id: int):
    """IKE w domu maklerskim — limit ~23.5k na 2025."""
    data = IKEAccountCreate(
        name="IKE w XTB",
        currency="PLN",
        institution_name="XTB",
        annual_limit=23472.00,
        annual_contributed=15000.0,
        cash_balance=3000.0,
    )
    result = ike_ikze_service.create_ike_account(db, user_id=user_id, data=data)
    print(f"   ✓ IKE: {result.asset.name} — cash {result.cash_balance:,.2f} PLN, "
          f"wpłacono {result.annual_contributed:,.2f}/{result.annual_limit:,.2f}")
    return result


def seed_ikze(db: Session, user_id: int):
    """IKZE — limit ~9.4k na 2025."""
    data = IKZEAccountCreate(
        name="IKZE w Bossa",
        currency="PLN",
        institution_name="Bossa",
        annual_limit=9388.80,
        annual_contributed=5000.0,
        cash_balance=500.0,
    )
    result = ike_ikze_service.create_ikze_account(db, user_id=user_id, data=data)
    print(f"   ✓ IKZE: {result.asset.name} — cash {result.cash_balance:,.2f} PLN, "
          f"wpłacono {result.annual_contributed:,.2f}/{result.annual_limit:,.2f}")
    return result


def seed_crypto(db: Session, user_id: int) -> None:
    """Jeden crypto wallet (sumarycznie, bez rozbicia na konkretne monety)."""
    data = CryptoWalletCreate(
        name="Ledger Nano",
        currency="USD",
        institution_name="Ledger (cold wallet)",
        wallet_address="bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh",
        current_value=8500.0,
    )
    result = crypto_service.create_crypto_wallet(db, user_id=user_id, data=data)
    print(f"   ✓ Crypto: {result.asset.name} — {result.current_value:,.2f} {result.asset.currency}")


def seed_holdings_in_ike(db: Session, user_id: int, ike_account_id: int) -> None:
    """Holdings w IKE — akcje polskie + globalny ETF + obligacja skarbowa."""
    holdings = [
        StockCreate(
            ticker="CDR",
            name="CD Projekt",
            quantity=50,
            avg_purchase_price=120.50,
            current_price=145.00,
            ike_account_id=ike_account_id,
        ),
        StockCreate(
            ticker="PKN",
            name="Orlen",
            quantity=30,
            avg_purchase_price=58.00,
            current_price=63.20,
            ike_account_id=ike_account_id,
        ),
        ETFCreate(
            ticker="EUNL.DE",
            name="iShares Core MSCI World UCITS ETF",
            quantity=20,
            avg_purchase_price=82.50,
            current_price=93.10,
            ike_account_id=ike_account_id,
        ),
        BondCreate(
            ticker="EDO1034",
            name="Obligacje skarbowe 10-letnie EDO",
            quantity=10,
            avg_purchase_price=100.00,
            current_price=102.50,
            ike_account_id=ike_account_id,
            face_value=100.00,
            coupon_rate=6.55,
            maturity_date=datetime(2034, 10, 31),
            issuer="Skarb Państwa RP",
        ),
    ]
    for data in holdings:
        result = holding_service.create_holding(db, user_id=user_id, data=data)
        print(f"   ✓ Holding[IKE]: {result.ticker} ({result.asset_class.value}) — "
              f"{result.quantity}× @ {result.current_price:,.2f}")


def seed_holdings_in_ikze(db: Session, user_id: int, ikze_account_id: int) -> None:
    """Holdings w IKZE — ETF amerykański + krypto (BTC). IKZE traktowane
    bardziej długoterminowo niż IKE, stąd mniej pozycji."""
    holdings = [
        ETFCreate(
            ticker="SXR8.DE",
            name="iShares Core S&P 500 UCITS ETF",
            quantity=8,
            avg_purchase_price=450.00,
            current_price=510.00,
            ike_account_id=ikze_account_id,
        ),
        CryptoCreate(
            ticker="BTC",
            name="Bitcoin",
            quantity=0.15,
            avg_purchase_price=65000.00,
            current_price=95000.00,
            ike_account_id=ikze_account_id,
        ),
    ]
    for data in holdings:
        result = holding_service.create_holding(db, user_id=user_id, data=data)
        print(f"   ✓ Holding[IKZE]: {result.ticker} ({result.asset_class.value}) — "
              f"{result.quantity}× @ {result.current_price:,.2f}")


# =========================================================
# ORKIESTRACJA
# =========================================================

def seed() -> None:
    print("=" * 60)
    print("FinApp — generator danych testowych (mock_data.py)")
    print("=" * 60)

    db = SessionLocal()
    try:
        clean_existing_demo(db)
        user = create_demo_user(db)

        print("\n📊 Tworzę aktywa demo usera:\n")

        print("→ Konta oszczędnościowe:")
        seed_savings(db, user.id)

        print("\n→ PPK:")
        seed_ppk(db, user.id)

        print("\n→ IKE:")
        ike = seed_ike(db, user.id)

        print("\n→ IKZE:")
        ikze = seed_ikze(db, user.id)

        print("\n→ Crypto wallet:")
        seed_crypto(db, user.id)

        print("\n→ Holdings w IKE (akcje + ETF + obligacja):")
        seed_holdings_in_ike(db, user.id, ike.asset_id)

        print("\n→ Holdings w IKZE (ETF + krypto):")
        seed_holdings_in_ikze(db, user.id, ikze.asset_id)

        print("\n" + "=" * 60)
        print("✓ Gotowe! Demo user utworzony z kompletnym portfelem.")
        print("=" * 60)
        print(f"\n  Email:  {DEMO_EMAIL}")
        print(f"  Hasło:  {DEMO_PASSWORD}")
        print(f"  ID:     {user.id}")
        print("\n  Zaloguj się przez POST /auth/login w Swaggerze")
        print("  http://localhost:8000/docs\n")
    finally:
        db.close()


if __name__ == "__main__":
    seed()