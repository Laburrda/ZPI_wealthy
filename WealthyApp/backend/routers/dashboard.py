from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db
from models.user import User
from services.auth_service import get_current_user
from schemas.dashboard import DashboardSummaryResponse
from services import dashboard_service

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/summary", response_model=DashboardSummaryResponse)
def get_dashboard_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Zwraca pełne podsumowanie portfela dla zalogowanego użytkownika.
    Używane przez Flutter jako dane startowe ekranu głównego.
    """
    return dashboard_service.get_dashboard_summary(db, user_id=current_user.id)