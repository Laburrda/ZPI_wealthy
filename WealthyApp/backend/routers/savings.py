from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from database import get_db
from models.saving_account import SavingsAccount
from schemas.asset import SavingsAccountCreate, SavingsAccountResponse
from services import savings_service

from models.user import User
from services.auth_service import get_current_user

router = APIRouter(prefix="/assets/savings", tags=["Savings"])

# === HELPER ===
# Mapuje obiekt ORM (SavingsAccount + relacja .asset) na płaski dict,
# z którego Pydantic zbuduje SavingsAccountResponse. To dlatego, że
# SavingsAccountResponse oczekuje pól z DWÓCH tabel (assets + savings_accounts)
# spłaszczonych w jeden obiekt JSON.
def _to_response(savings: SavingsAccount) -> dict:
    return {
        "id": savings.asset.id,
        "asset_type": savings.asset.asset_type,
        "name": savings.asset.name,
        "currency": savings.asset.currency,
        "institution_name": savings.institution_name,
        "interest_rate": savings.interest_rate,
        "current_balance": savings.current_balance,
        "balance_synced_at": savings.balance_synced_at,
        "created_at": savings.asset.created_at,
        "updated_at": savings.asset.updated_at,
    }


# === ENDPOINTY ===

@router.post(
    "/",
    response_model=SavingsAccountResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Utwórz nowe konto oszczędnościowe",
)
def create_savings_account_endpoint(
    data: SavingsAccountCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    savings = savings_service.create_savings_account(db, user_id=current_user.id, data=data)
    return _to_response(savings)


@router.get(
    "/",
    response_model=list[SavingsAccountResponse],
    summary="Lista wszystkich kont oszczędnościowych użytkownika",
)
def list_savings_accounts_endpoint(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    accounts = savings_service.list_savings_accounts(db, user_id=current_user.id)
    return [_to_response(a) for a in accounts]


@router.get(
    "/{asset_id}",
    response_model=SavingsAccountResponse,
    summary="Pobierz pojedyncze konto oszczędnościowe po ID",
)
def get_savings_account_endpoint(
    asset_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    savings = savings_service.get_savings_account(db, user_id=current_user.id, asset_id=asset_id)
    return _to_response(savings)


@router.delete(
    "/{asset_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Usuń konto oszczędnościowe",
)
def delete_savings_account_endpoint(
    asset_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    savings_service.delete_savings_account(db, user_id=current_user.id, asset_id=asset_id)


# TODO: PUT /{asset_id} - czeka na SavingsAccountUpdate w schemas/asset.py
# (DEV A oznaczył w TODO że dorobi Update schemas później)