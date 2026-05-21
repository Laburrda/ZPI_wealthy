from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status

from models.asset import Asset
from models.ike_ikze_account import IKEAccount
from enums import AssetType, IkeIkzeType
from schemas.asset import IKEAccountCreate, IKZEAccountCreate


# =========================================================
# PRYWATNE HELPERY - logika wspólna dla IKE i IKZE
# =========================================================

def _create(
    db: Session,
    user_id: int,
    data: IKEAccountCreate | IKZEAccountCreate,
    asset_type: AssetType,
    subtype: IkeIkzeType,
) -> IKEAccount:
    """Atomowo tworzy Asset (IKE lub IKZE) + IKEAccount."""
    try:
        asset = Asset(
            user_id=user_id,
            asset_type=asset_type,
            name=data.name,
            currency=data.currency,
        )
        db.add(asset)
        db.flush()

        ike = IKEAccount(
            asset_id=asset.id,
            institution_name=data.institution_name,
            account_subtype=subtype,
            annual_limit=data.annual_limit,
            annual_contributed=data.annual_contributed,
            cash_balance=data.cash_balance,
        )
        db.add(ike)
        db.commit()
        db.refresh(ike)
        return ike
    except Exception:
        db.rollback()
        raise


def _get(
    db: Session,
    user_id: int,
    asset_id: int,
    asset_type: AssetType,
) -> IKEAccount:
    ike = (
        db.query(IKEAccount)
        .options(joinedload(IKEAccount.asset))
        .join(Asset, Asset.id == IKEAccount.asset_id)
        .filter(Asset.id == asset_id)
        .filter(Asset.user_id == user_id)
        .filter(Asset.asset_type == asset_type)  # KLUCZOWE: filtr IKE vs IKZE
        .first()
    )
    if ike is None:
        label = "IKE" if asset_type == AssetType.IKE else "IKZE"
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Konto {label} o id={asset_id} nie znalezione.",
        )
    return ike


def _list(
    db: Session,
    user_id: int,
    asset_type: AssetType,
) -> list[IKEAccount]:
    return (
        db.query(IKEAccount)
        .options(joinedload(IKEAccount.asset))
        .join(Asset, Asset.id == IKEAccount.asset_id)
        .filter(Asset.user_id == user_id)
        .filter(Asset.asset_type == asset_type)
        .all()
    )


def _delete(
    db: Session,
    user_id: int,
    asset_id: int,
    asset_type: AssetType,
) -> None:
    asset = (
        db.query(Asset)
        .filter(Asset.id == asset_id)
        .filter(Asset.user_id == user_id)
        .filter(Asset.asset_type == asset_type)
        .first()
    )
    if asset is None:
        label = "IKE" if asset_type == AssetType.IKE else "IKZE"
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Konto {label} o id={asset_id} nie znalezione.",
        )
    db.delete(asset)
    db.commit()


# =========================================================
# PUBLICZNE API - IKE
# =========================================================

def create_ike_account(db: Session, user_id: int, data: IKEAccountCreate) -> IKEAccount:
    return _create(db, user_id, data, AssetType.IKE, IkeIkzeType.IKE)

def get_ike_account(db: Session, user_id: int, asset_id: int) -> IKEAccount:
    return _get(db, user_id, asset_id, AssetType.IKE)

def list_ike_accounts(db: Session, user_id: int) -> list[IKEAccount]:
    return _list(db, user_id, AssetType.IKE)

def delete_ike_account(db: Session, user_id: int, asset_id: int) -> None:
    return _delete(db, user_id, asset_id, AssetType.IKE)


# =========================================================
# PUBLICZNE API - IKZE
# =========================================================

def create_ikze_account(db: Session, user_id: int, data: IKZEAccountCreate) -> IKEAccount:
    return _create(db, user_id, data, AssetType.IKZE, IkeIkzeType.IKZE)

def get_ikze_account(db: Session, user_id: int, asset_id: int) -> IKEAccount:
    return _get(db, user_id, asset_id, AssetType.IKZE)

def list_ikze_accounts(db: Session, user_id: int) -> list[IKEAccount]:
    return _list(db, user_id, AssetType.IKZE)

def delete_ikze_account(db: Session, user_id: int, asset_id: int) -> None:
    return _delete(db, user_id, asset_id, AssetType.IKZE)