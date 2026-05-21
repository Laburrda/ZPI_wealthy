from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status

from models.asset import Asset
from models.holding import Holding
from models.bond_details import BondDetails
from models.cdf_details import CFDDetails  # UWAGA: typo w nazwie pliku DEV A (cdf zamiast cfd)
from models.ike_ikze_account import IKEAccount
from schemas.holding import (
    StockCreate, ETFCreate, BondCreate, CFDCreate, CryptoCreate,
)


def _validate_ike_ownership(
    db: Session,
    user_id: int,
    ike_account_id: int | None,
) -> None:
    """
    Jeśli holding ma być w IKE/IKZE, sprawdzamy że to konto istnieje
    i należy do TEGO usera. Inaczej ktoś mógłby wstawiać swoje holdings
    do cudzego IKE - to byłoby BARDZO złe.
    """
    if ike_account_id is None:
        return
    exists = (
        db.query(IKEAccount.asset_id)
        .join(Asset, Asset.id == IKEAccount.asset_id)
        .filter(IKEAccount.asset_id == ike_account_id)
        .filter(Asset.user_id == user_id)
        .first()
    )
    if exists is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Konto IKE/IKZE o id={ike_account_id} nie istnieje lub nie należy do Ciebie.",
        )


def create_holding(
    db: Session,
    user_id: int,
    data: StockCreate | ETFCreate | BondCreate | CFDCreate | CryptoCreate,
) -> Holding:
    """
    Tworzy nowy holding (1 wiersz w `holdings`). Dla BOND/CFD dorzuca
    drugi wiersz w tabeli rozszerzającej, w TEJ SAMEJ transakcji.
    """
    _validate_ike_ownership(db, user_id, data.ike_account_id)

    try:
        # KROK 1: główny wiersz w `holdings` (wspólne pola dla wszystkich klas)
        holding = Holding(
            user_id=user_id,
            ike_account_id=data.ike_account_id,
            ticker=data.ticker,
            name=data.name,
            asset_class=data.asset_class,
            quantity=data.quantity,
            avg_purchase_price=data.avg_purchase_price,
            current_price=data.current_price,
        )
        db.add(holding)
        db.flush()  # potrzebujemy holding.id do tabel rozszerzających

        # KROK 2: tabela rozszerzająca (tylko BOND/CFD - STOCK/ETF/CRYPTO nie mają)
        if isinstance(data, BondCreate):
            db.add(BondDetails(
                holding_id=holding.id,
                face_value=data.face_value,
                coupon_rate=data.coupon_rate,
                maturity_date=data.maturity_date,
                issuer=data.issuer,
            ))
        elif isinstance(data, CFDCreate):
            db.add(CFDDetails(
                holding_id=holding.id,
                leverage=data.leverage,
                margin_used=data.margin_used,
                direction=data.direction,
            ))

        db.commit()
        db.refresh(holding)
        return holding
    except Exception:
        db.rollback()
        raise


def get_holding(
    db: Session,
    user_id: int,
    holding_id: int,
) -> Holding:
    """Pobiera holding użytkownika z załadowanymi bond_details/cfd_details (jeśli są)."""
    holding = (
        db.query(Holding)
        .options(
            joinedload(Holding.bond_details),
            joinedload(Holding.cfd_details),
        )
        .filter(Holding.id == holding_id)
        .filter(Holding.user_id == user_id)
        .first()
    )
    if holding is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Holding o id={holding_id} nie znaleziony.",
        )
    return holding


def list_holdings(
    db: Session,
    user_id: int,
    ike_account_id: int | None = None,
) -> list[Holding]:
    """
    Listuje holdings użytkownika. Opcjonalnie filtruje do konkretnego IKE/IKZE
    (przydatne dla widoku "co mam w moim IKE w XTB").
    """
    query = (
        db.query(Holding)
        .options(
            joinedload(Holding.bond_details),
            joinedload(Holding.cfd_details),
        )
        .filter(Holding.user_id == user_id)
    )
    if ike_account_id is not None:
        query = query.filter(Holding.ike_account_id == ike_account_id)
    return query.all()


def delete_holding(
    db: Session,
    user_id: int,
    holding_id: int,
) -> None:
    """Usuwa holding. CASCADE w bazie usuwa też bond_details/cfd_details."""
    holding = (
        db.query(Holding)
        .filter(Holding.id == holding_id)
        .filter(Holding.user_id == user_id)
        .first()
    )
    if holding is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Holding o id={holding_id} nie znaleziony.",
        )
    db.delete(holding)
    db.commit()