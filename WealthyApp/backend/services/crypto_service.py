from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status

from models.asset import Asset
from models.crypto_wallet import CryptoWallet
from enums import AssetType
from schemas.asset import CryptoWalletCreate


def create_crypto_wallet(
    db: Session,
    user_id: int,
    data: CryptoWalletCreate,
) -> CryptoWallet:
    """Atomowo tworzy Asset (typ CRYPTO) + CryptoWallet."""
    try:
        asset = Asset(
            user_id=user_id,
            asset_type=AssetType.CRYPTO,
            name=data.name,
            currency=data.currency,
        )
        db.add(asset)
        db.flush()

        wallet = CryptoWallet(
            asset_id=asset.id,
            institution_name=data.institution_name,
            wallet_address=data.wallet_address,
            current_value=data.current_value,
        )
        db.add(wallet)
        db.commit()
        db.refresh(wallet)
        return wallet
    except Exception:
        db.rollback()
        raise


def get_crypto_wallet(
    db: Session,
    user_id: int,
    asset_id: int,
) -> CryptoWallet:
    wallet = (
        db.query(CryptoWallet)
        .options(joinedload(CryptoWallet.asset))
        .join(Asset, Asset.id == CryptoWallet.asset_id)
        .filter(Asset.id == asset_id)
        .filter(Asset.user_id == user_id)
        .first()
    )
    if wallet is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Portfel krypto o id={asset_id} nie znaleziony.",
        )
    return wallet


def list_crypto_wallets(
    db: Session,
    user_id: int,
) -> list[CryptoWallet]:
    return (
        db.query(CryptoWallet)
        .options(joinedload(CryptoWallet.asset))
        .join(Asset, Asset.id == CryptoWallet.asset_id)
        .filter(Asset.user_id == user_id)
        .all()
    )


def delete_crypto_wallet(
    db: Session,
    user_id: int,
    asset_id: int,
) -> None:
    asset = (
        db.query(Asset)
        .filter(Asset.id == asset_id)
        .filter(Asset.user_id == user_id)
        .filter(Asset.asset_type == AssetType.CRYPTO)
        .first()
    )
    if asset is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Portfel krypto o id={asset_id} nie znaleziony.",
        )
    db.delete(asset)
    db.commit()