from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from database import get_db
from models.crypto_wallet import CryptoWallet
from schemas.asset import CryptoWalletCreate, CryptoWalletResponse
from services import crypto_service

from models.user import User
from services.auth_service import get_current_user

router = APIRouter(prefix="/assets/crypto", tags=["Crypto"])

# === HELPER ===
def _to_response(wallet: CryptoWallet) -> dict:
    return {
        "id": wallet.asset.id,
        "asset_type": wallet.asset.asset_type,
        "name": wallet.asset.name,
        "currency": wallet.asset.currency,
        "institution_name": wallet.institution_name,
        "wallet_address": wallet.wallet_address,
        "current_value": wallet.current_value,
        "value_updated_at": wallet.value_updated_at,
        "created_at": wallet.asset.created_at,
        "updated_at": wallet.asset.updated_at,
    }


# === ENDPOINTY ===

@router.post(
    "/",
    response_model=CryptoWalletResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Utwórz nowy portfel krypto",
)
def create_crypto_endpoint(
    data: CryptoWalletCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    wallet = crypto_service.create_crypto_wallet(db, user_id=current_user.id, data=data)
    return _to_response(wallet)


@router.get(
    "/",
    response_model=list[CryptoWalletResponse],
    summary="Lista wszystkich portfeli krypto użytkownika",
)
def list_crypto_endpoint(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    wallets = crypto_service.list_crypto_wallets(db, user_id=current_user.id)
    return [_to_response(w) for w in wallets]


@router.get(
    "/{asset_id}",
    response_model=CryptoWalletResponse,
    summary="Pobierz pojedynczy portfel krypto po ID",
)
def get_crypto_endpoint(
    asset_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    wallet = crypto_service.get_crypto_wallet(db, user_id=current_user.id, asset_id=asset_id)
    return _to_response(wallet)


@router.delete(
    "/{asset_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Usuń portfel krypto",
)
def delete_crypto_endpoint(
    asset_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    crypto_service.delete_crypto_wallet(db, user_id=current_user.id, asset_id=asset_id)


# TODO: PUT - czeka na CryptoWalletUpdate w schemas/asset.py