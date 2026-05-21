from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from database import get_db
from models.ike_ikze_account import IKEAccount
from schemas.asset import (
    IKEAccountCreate, IKEAccountResponse,
    IKZEAccountCreate, IKZEAccountResponse,
)
from services import ike_ikze_service


# Dwa osobne routery - każdy ze swoim prefixem i tagiem
ike_router = APIRouter(prefix="/assets/ike", tags=["IKE"])
ikze_router = APIRouter(prefix="/assets/ikze", tags=["IKZE"])


# === ZAŚLEPKA AUTORYZACJI ===
# TODO: Zastąpić importem z auth/, kiedy DEV A skończy JWT.
def get_current_user_id() -> int:
    return 1


# === HELPER (wspólny dla IKE i IKZE - kształt response identyczny) ===
def _to_response(ike: IKEAccount) -> dict:
    return {
        "id": ike.asset.id,
        "asset_type": ike.asset.asset_type,
        "name": ike.asset.name,
        "currency": ike.asset.currency,
        "account_subtype": ike.account_subtype,
        "institution_name": ike.institution_name,
        "annual_limit": ike.annual_limit,
        "annual_contributed": ike.annual_contributed,
        "cash_balance": ike.cash_balance,
        "balance_synced_at": ike.balance_synced_at,
        "created_at": ike.asset.created_at,
        "updated_at": ike.asset.updated_at,
    }


# =========================================================
# ENDPOINTY IKE
# =========================================================

@ike_router.post(
    "/",
    response_model=IKEAccountResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Utwórz nowe konto IKE",
)
def create_ike_endpoint(
    data: IKEAccountCreate,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    ike = ike_ikze_service.create_ike_account(db, user_id=user_id, data=data)
    return _to_response(ike)


@ike_router.get(
    "/",
    response_model=list[IKEAccountResponse],
    summary="Lista wszystkich kont IKE użytkownika",
)
def list_ike_endpoint(
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    accounts = ike_ikze_service.list_ike_accounts(db, user_id=user_id)
    return [_to_response(a) for a in accounts]


@ike_router.get(
    "/{asset_id}",
    response_model=IKEAccountResponse,
    summary="Pobierz pojedyncze konto IKE po ID",
)
def get_ike_endpoint(
    asset_id: int,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    ike = ike_ikze_service.get_ike_account(db, user_id=user_id, asset_id=asset_id)
    return _to_response(ike)


@ike_router.delete(
    "/{asset_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Usuń konto IKE",
)
def delete_ike_endpoint(
    asset_id: int,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    ike_ikze_service.delete_ike_account(db, user_id=user_id, asset_id=asset_id)


# =========================================================
# ENDPOINTY IKZE
# =========================================================

@ikze_router.post(
    "/",
    response_model=IKZEAccountResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Utwórz nowe konto IKZE",
)
def create_ikze_endpoint(
    data: IKZEAccountCreate,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    ikze = ike_ikze_service.create_ikze_account(db, user_id=user_id, data=data)
    return _to_response(ikze)


@ikze_router.get(
    "/",
    response_model=list[IKZEAccountResponse],
    summary="Lista wszystkich kont IKZE użytkownika",
)
def list_ikze_endpoint(
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    accounts = ike_ikze_service.list_ikze_accounts(db, user_id=user_id)
    return [_to_response(a) for a in accounts]


@ikze_router.get(
    "/{asset_id}",
    response_model=IKZEAccountResponse,
    summary="Pobierz pojedyncze konto IKZE po ID",
)
def get_ikze_endpoint(
    asset_id: int,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    ikze = ike_ikze_service.get_ikze_account(db, user_id=user_id, asset_id=asset_id)
    return _to_response(ikze)


@ikze_router.delete(
    "/{asset_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Usuń konto IKZE",
)
def delete_ikze_endpoint(
    asset_id: int,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    ike_ikze_service.delete_ikze_account(db, user_id=user_id, asset_id=asset_id)


# TODO: PUT - czeka na IKEAccountUpdate / IKZEAccountUpdate w schemas/asset.py