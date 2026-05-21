from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status

from models.asset import Asset
from models.ppk_account import PPKAccount
from enums import AssetType
from schemas.asset import PPKAccountCreate


def create_ppk_account(
    db: Session,
    user_id: int,
    data: PPKAccountCreate,
) -> PPKAccount:
    """Atomowo tworzy Asset (typ PPK) + PPKAccount w jednej transakcji."""
    try:
        asset = Asset(
            user_id=user_id,
            asset_type=AssetType.PPK,
            name=data.name,
            currency=data.currency,
        )
        db.add(asset)
        db.flush()  # potrzebujemy asset.id do FK

        ppk = PPKAccount(
            asset_id=asset.id,
            institution_name=data.institution_name,
            fund_name=data.fund_name,
            employee_rate=data.employee_rate,
            employer_rate=data.employer_rate,
            current_value=data.current_value,
        )
        db.add(ppk)
        db.commit()
        db.refresh(ppk)
        return ppk
    except Exception:
        db.rollback()
        raise


def get_ppk_account(
    db: Session,
    user_id: int,
    asset_id: int,
) -> PPKAccount:
    """Pobiera konto PPK danego użytkownika. 404 jeśli nie istnieje lub nie należy."""
    ppk = (
        db.query(PPKAccount)
        .options(joinedload(PPKAccount.asset))
        .join(Asset, Asset.id == PPKAccount.asset_id)
        .filter(Asset.id == asset_id)
        .filter(Asset.user_id == user_id)
        .first()
    )
    if ppk is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Konto PPK o id={asset_id} nie znalezione.",
        )
    return ppk


def list_ppk_accounts(
    db: Session,
    user_id: int,
) -> list[PPKAccount]:
    """Listuje wszystkie konta PPK danego użytkownika."""
    return (
        db.query(PPKAccount)
        .options(joinedload(PPKAccount.asset))
        .join(Asset, Asset.id == PPKAccount.asset_id)
        .filter(Asset.user_id == user_id)
        .all()
    )


def delete_ppk_account(
    db: Session,
    user_id: int,
    asset_id: int,
) -> None:
    """Usuwa konto PPK (CASCADE usuwa też ppk_accounts)."""
    asset = (
        db.query(Asset)
        .filter(Asset.id == asset_id)
        .filter(Asset.user_id == user_id)
        .filter(Asset.asset_type == AssetType.PPK)
        .first()
    )
    if asset is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Konto PPK o id={asset_id} nie znalezione.",
        )
    db.delete(asset)
    db.commit()