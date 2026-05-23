from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from models.category import Category
from models.transaction import Transaction
from schemas.transaction import (
    CategoryCreate,
    TransactionCreate,
    TransactionFilters,
    TransactionUpdate,
)


# ══════════════════════════════════════════════════════════
#  CATEGORY
# ══════════════════════════════════════════════════════════

def get_categories(db: Session, user_id: int) -> list[Category]:
    """
    Zwraca kategorie domyślne (is_default=True, user_id=NULL)
    ORAZ własne kategorie zalogowanego użytkownika.
    """
    stmt = select(Category).where(
        (Category.is_default == True) | (Category.user_id == user_id)
    ).order_by(Category.is_default.desc(), Category.name)
    return list(db.scalars(stmt).all())


def create_category(db: Session, user_id: int, data: CategoryCreate) -> Category:
    category = Category(
        user_id=user_id,
        name=data.name,
        transaction_type=data.transaction_type,
        icon=data.icon,
        color=data.color,
        is_default=False,   # kategorie tworzone przez usera nigdy nie są domyślne
    )
    db.add(category)
    db.commit()
    db.refresh(category)
    return category


def delete_category(db: Session, user_id: int, category_id: int) -> None:
    category = db.get(Category, category_id)

    if not category:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kategoria nie istnieje")

    # user nie może usunąć kategorii domyślnej ani cudzej
    if category.is_default or category.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Nie możesz usunąć tej kategorii",
        )

    db.delete(category)
    db.commit()


# ══════════════════════════════════════════════════════════
#  TRANSACTION — odczyt
# ══════════════════════════════════════════════════════════

def _base_query(user_id: int):
    """
    Bazowe zapytanie dla wszystkich GET — zawsze filtruje po user_id
    i eager-loaduje kategorię (joinedload) żeby uniknąć N+1 queries.
    """
    return (
        select(Transaction)
        .where(Transaction.user_id == user_id)
        .options(joinedload(Transaction.category))
    )


def list_transactions(
    db: Session, user_id: int, filters: TransactionFilters
) -> list[Transaction]:
    stmt = _base_query(user_id)

    # każdy filtr dokładany tylko jeśli został podany
    if filters.transaction_type:
        stmt = stmt.where(Transaction.transaction_type == filters.transaction_type)
    if filters.category_id:
        stmt = stmt.where(Transaction.category_id == filters.category_id)
    if filters.date_from:
        stmt = stmt.where(Transaction.transaction_date >= filters.date_from)
    if filters.date_to:
        stmt = stmt.where(Transaction.transaction_date <= filters.date_to)
    if filters.min_amount:
        stmt = stmt.where(Transaction.amount >= filters.min_amount)
    if filters.max_amount:
        stmt = stmt.where(Transaction.amount <= filters.max_amount)

    stmt = stmt.order_by(Transaction.transaction_date.desc())
    return list(db.scalars(stmt).all())


def get_transaction(db: Session, user_id: int, transaction_id: int) -> Transaction:
    stmt = _base_query(user_id).where(Transaction.id == transaction_id)
    transaction = db.scalars(stmt).first()

    if not transaction:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Transakcja nie istnieje")
    return transaction


# ══════════════════════════════════════════════════════════
#  TRANSACTION — zapis
# ══════════════════════════════════════════════════════════

def _validate_category(db: Session, user_id: int, category_id: int | None) -> None:
    """
    Sprawdza czy kategoria istnieje i należy do tego usera (lub jest domyślna).
    Wywoływana przed CREATE i UPDATE.
    """
    if category_id is None:
        return
    category = db.get(Category, category_id)
    if not category:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Kategoria nie istnieje")
    if not category.is_default and category.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Nie możesz użyć tej kategorii",
        )


def create_transaction(db: Session, user_id: int, data: TransactionCreate) -> Transaction:
    _validate_category(db, user_id, data.category_id)

    transaction = Transaction(
        user_id=user_id,
        transaction_type=data.transaction_type,
        amount=data.amount,
        currency=data.currency,
        category_id=data.category_id,
        transaction_date=data.transaction_date,
        description=data.description,
        notes=data.notes,
    )
    db.add(transaction)
    db.commit()
    db.refresh(transaction)

    # refresh nie ładuje relacji — potrzebny osobny get z joinedload
    return get_transaction(db, user_id, transaction.id)


def update_transaction(
    db: Session, user_id: int, transaction_id: int, data: TransactionUpdate
) -> Transaction:
    transaction = get_transaction(db, user_id, transaction_id)

    # aktualizuj tylko pola które faktycznie przyszły w requeście
    update_data = data.model_dump(exclude_unset=True)

    if "category_id" in update_data:
        _validate_category(db, user_id, update_data["category_id"])

    for field, value in update_data.items():
        setattr(transaction, field, value)

    db.commit()
    db.refresh(transaction)
    return get_transaction(db, user_id, transaction_id)


def delete_transaction(db: Session, user_id: int, transaction_id: int) -> None:
    transaction = get_transaction(db, user_id, transaction_id)
    db.delete(transaction)
    db.commit()