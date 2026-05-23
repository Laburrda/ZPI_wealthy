from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from database import get_db
from models.user import User
from schemas.transaction import (
    CategoryCreate,
    CategoryResponse,
    TransactionCreate,
    TransactionFilters,
    TransactionResponse,
    TransactionUpdate,
)
from services import transaction_service
from services.auth_service import get_current_user

router = APIRouter(prefix="/transactions", tags=["Transactions"])
categories_router = APIRouter(prefix="/categories", tags=["Categories"])


# ══════════════════════════════════════════════════════════
#  CATEGORIES
# ══════════════════════════════════════════════════════════

@categories_router.get(
    "/",
    response_model=list[CategoryResponse],
    summary="Lista kategorii (domyślne + własne usera)",
)
def list_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return transaction_service.get_categories(db, user_id=current_user.id)


@categories_router.post(
    "/",
    response_model=CategoryResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Utwórz własną kategorię",
)
def create_category(
    data: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return transaction_service.create_category(db, user_id=current_user.id, data=data)


@categories_router.delete(
    "/{category_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Usuń własną kategorię (transakcje zostają, category_id → NULL)",
)
def delete_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    transaction_service.delete_category(db, user_id=current_user.id, category_id=category_id)


# ══════════════════════════════════════════════════════════
#  TRANSACTIONS
# ══════════════════════════════════════════════════════════

@router.get(
    "/",
    response_model=list[TransactionResponse],
    summary="Lista transakcji z opcjonalnym filtrowaniem",
)
def list_transactions(
    filters: TransactionFilters = Depends(),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return transaction_service.list_transactions(db, user_id=current_user.id, filters=filters)


@router.post(
    "/",
    response_model=TransactionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Dodaj nową transakcję",
)
def create_transaction(
    data: TransactionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return transaction_service.create_transaction(db, user_id=current_user.id, data=data)


@router.get(
    "/{transaction_id}",
    response_model=TransactionResponse,
    summary="Pobierz transakcję po ID",
)
def get_transaction(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return transaction_service.get_transaction(db, user_id=current_user.id, transaction_id=transaction_id)


@router.put(
    "/{transaction_id}",
    response_model=TransactionResponse,
    summary="Zaktualizuj transakcję (tylko przesłane pola)",
)
def update_transaction(
    transaction_id: int,
    data: TransactionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return transaction_service.update_transaction(
        db, user_id=current_user.id, transaction_id=transaction_id, data=data
    )


@router.delete(
    "/{transaction_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Usuń transakcję",
)
def delete_transaction(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    transaction_service.delete_transaction(db, user_id=current_user.id, transaction_id=transaction_id)