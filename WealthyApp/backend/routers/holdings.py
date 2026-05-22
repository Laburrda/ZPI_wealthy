from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from database import get_db
from models.holding import Holding
from schemas.holding import HoldingCreate, HoldingResponse
from services import holding_service
from enums import AssetClass

from models.user import User
from services.auth_service import get_current_user


router = APIRouter(prefix="/holdings", tags=["Holdings"])

# === HELPER ===
def _to_response(holding: Holding) -> dict:
    """
    Spłaszcza Holding + ewentualne bond_details / cfd_details
    do JEDNEGO dict zgodnego z odpowiednim wariantem HoldingResponse.
    FastAPI sam dopasuje do właściwego sub-schematu po polu `asset_class`.
    """
    base = {
        "id": holding.id,
        "asset_class": holding.asset_class,
        "ike_account_id": holding.ike_account_id,
        "ticker": holding.ticker,
        "name": holding.name,
        "quantity": holding.quantity,
        "avg_purchase_price": holding.avg_purchase_price,
        "current_price": holding.current_price,
        "entry_date": holding.entry_date,
        "last_price_update": holding.last_price_update,
    }
    # Dla BOND/CFD dokładamy pola z tabel rozszerzających
    if holding.asset_class == AssetClass.BOND and holding.bond_details:
        base.update({
            "face_value": holding.bond_details.face_value,
            "coupon_rate": holding.bond_details.coupon_rate,
            "maturity_date": holding.bond_details.maturity_date,
            "issuer": holding.bond_details.issuer,
        })
    elif holding.asset_class == AssetClass.CFD and holding.cfd_details:
        base.update({
            "leverage": holding.cfd_details.leverage,
            "margin_used": holding.cfd_details.margin_used,
            "direction": holding.cfd_details.direction,
        })
    return base


# === ENDPOINTY ===

@router.post(
    "/",
    response_model=HoldingResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Utwórz nowy holding (akcja/ETF/obligacja/CFD/krypto)",
)
def create_holding_endpoint(
    data: HoldingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    holding = holding_service.create_holding(db, user_id=current_user.id, data=data)
    return _to_response(holding)


@router.get(
    "/",
    response_model=list[HoldingResponse],
    summary="Lista holdings (opcjonalnie filtrowana po koncie IKE/IKZE)",
)
def list_holdings_endpoint(
    ike_account_id: int | None = Query(
        None,
        description="Jeśli podane - pokaże tylko holdings w tym konkretnym IKE/IKZE",
    ),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    holdings = holding_service.list_holdings(
        db, user_id=current_user.id, ike_account_id=ike_account_id
    )
    return [_to_response(h) for h in holdings]


@router.get(
    "/{holding_id}",
    response_model=HoldingResponse,
    summary="Pobierz pojedynczy holding po ID",
)
def get_holding_endpoint(
    holding_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    holding = holding_service.get_holding(db, user_id=current_user.id, holding_id=holding_id)
    return _to_response(holding)


@router.delete(
    "/{holding_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Usuń holding (CASCADE usunie też bond_details/cfd_details)",
)
def delete_holding_endpoint(
    holding_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    holding_service.delete_holding(db, user_id=current_user.id, holding_id=holding_id)


# TODO: PUT - czeka na HoldingUpdate w schemas/holding.py