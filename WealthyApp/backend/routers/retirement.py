from fastapi import APIRouter, Depends, status
from models.user import User
from schemas.retirement import (
    ZusProjectionRequest, ZusProjectionResponse,
    PrivateProjectionRequest, PrivateProjectionResponse,
)
from services import retirement_service
from services.auth_service import get_current_user


router = APIRouter(prefix="/retirement", tags=["Retirement Calculator"])


@router.post(
    "/zus-projection",
    response_model=ZusProjectionResponse,
    status_code=status.HTTP_200_OK,
    summary="Symulacja emerytury z ZUS",
    description=(
        "Oblicza orientacyjną wysokość przyszłej emerytury ZUS na podstawie "
        "obecnego wieku, wynagrodzenia, kapitału i założonych stóp wzrostu. "
        "Endpoint stateless - nie zapisuje wyników w bazie."
    ),
)
def zus_projection_endpoint(
    data: ZusProjectionRequest,
    current_user: User = Depends(get_current_user),  # wymaga zalogowania
):
    return retirement_service.calculate_zus_projection(data)


@router.post(
    "/private-projection",
    response_model=PrivateProjectionResponse,
    status_code=status.HTTP_200_OK,
    summary="Symulacja prywatnej emerytury (4% rule)",
    description=(
        "Oblicza wartość przyszłego portfela inwestycyjnego oraz bezpieczny "
        "miesięczny dochód metodą 4% rule. Endpoint stateless."
    ),
)
def private_projection_endpoint(
    data: PrivateProjectionRequest,
    current_user: User = Depends(get_current_user),
):
    return retirement_service.calculate_private_projection(data)