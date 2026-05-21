from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from database import get_db
from models.ppk_account import PPKAccount
from schemas.asset import PPKAccountCreate, PPKAccountResponse
from services import ppk_service


router = APIRouter(prefix="/assets/ppk", tags=["PPK"])


# === ZAŚLEPKA AUTORYZACJI ===
# TODO: Zastąpić importem z auth/, kiedy DEV A skończy JWT.
def get_current_user_id() -> int:
    return 1


# === HELPER ===
def _to_response(ppk: PPKAccount) -> dict:
    """Spłaszcza obiekt ORM (PPKAccount + .asset) do dict zgodnego z PPKAccountResponse."""
    return {
        "id": ppk.asset.id,
        "asset_type": ppk.asset.asset_type,
        "name": ppk.asset.name,
        "currency": ppk.asset.currency,
        "institution_name": ppk.institution_name,
        "fund_name": ppk.fund_name,
        "employee_rate": ppk.employee_rate,
        "employer_rate": ppk.employer_rate,
        "current_value": ppk.current_value,
        "value_updated_at": ppk.value_updated_at,
        "created_at": ppk.asset.created_at,
        "updated_at": ppk.asset.updated_at,
    }


# === ENDPOINTY ===

@router.post(
    "/",
    response_model=PPKAccountResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Utwórz nowe konto PPK",
)
def create_ppk_account_endpoint(
    data: PPKAccountCreate,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    ppk = ppk_service.create_ppk_account(db, user_id=user_id, data=data)
    return _to_response(ppk)


@router.get(
    "/",
    response_model=list[PPKAccountResponse],
    summary="Lista wszystkich kont PPK użytkownika",
)
def list_ppk_accounts_endpoint(
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    accounts = ppk_service.list_ppk_accounts(db, user_id=user_id)
    return [_to_response(a) for a in accounts]


@router.get(
    "/{asset_id}",
    response_model=PPKAccountResponse,
    summary="Pobierz pojedyncze konto PPK po ID",
)
def get_ppk_account_endpoint(
    asset_id: int,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    ppk = ppk_service.get_ppk_account(db, user_id=user_id, asset_id=asset_id)
    return _to_response(ppk)


@router.delete(
    "/{asset_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Usuń konto PPK",
)
def delete_ppk_account_endpoint(
    asset_id: int,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    ppk_service.delete_ppk_account(db, user_id=user_id, asset_id=asset_id)


# TODO: PUT /{asset_id} - czeka na PPKAccountUpdate w schemas/asset.py