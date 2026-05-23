from datetime import date, datetime

from pydantic import BaseModel, Field, field_validator

from enums import ExpenseIncome


# ══════════════════════════════════════════════════════════
#  CATEGORY
# ══════════════════════════════════════════════════════════

class CategoryCreate(BaseModel):
    name: str = Field(..., max_length=80, examples=["Jedzenie"])
    transaction_type: ExpenseIncome | None = None
    icon: str | None = Field(None, max_length=50, examples=["🍕"])
    color: str | None = Field(None, max_length=7, examples=["#FF5733"])

    # walidator — kolor musi być poprawnym HEX jeśli podany
    @field_validator("color")
    @classmethod
    def validate_color(cls, v: str | None) -> str | None:
        if v is not None and not v.startswith("#"):
            raise ValueError("Kolor musi być w formacie HEX, np. '#FF5733'")
        return v


class CategoryResponse(BaseModel):
    id: int
    name: str
    transaction_type: ExpenseIncome | None
    icon: str | None
    color: str | None
    is_default: bool

    model_config = {"from_attributes": True}


# ══════════════════════════════════════════════════════════
#  TRANSACTION — tworzenie
# ══════════════════════════════════════════════════════════

class TransactionCreate(BaseModel):
    transaction_type: ExpenseIncome
    amount: float = Field(..., gt=0, description="Kwota musi być większa od 0")
    currency: str = Field("PLN", max_length=3, examples=["PLN"])
    category_id: int | None = None
    transaction_date: date
    description: str | None = Field(None, max_length=255)
    notes: str | None = None


# ══════════════════════════════════════════════════════════
#  TRANSACTION — edycja (wszystkie pola opcjonalne)
# ══════════════════════════════════════════════════════════

class TransactionUpdate(BaseModel):
    """
    Wszystkie pola opcjonalne — PATCH semantyka.
    Serwis aktualizuje tylko te pola które zostały przesłane (nie są None).
    """
    transaction_type: ExpenseIncome | None = None
    amount: float | None = Field(None, gt=0)
    currency: str | None = Field(None, max_length=3)
    category_id: int | None = None
    transaction_date: date | None = None
    description: str | None = None
    notes: str | None = None


# ══════════════════════════════════════════════════════════
#  TRANSACTION — odpowiedź API
# ══════════════════════════════════════════════════════════

class TransactionResponse(BaseModel):
    id: int
    transaction_type: ExpenseIncome
    amount: float
    currency: str
    category_id: int | None
    category: CategoryResponse | None   # zagnieżdżony obiekt kategorii — Flutter nie musi robić drugiego requesta
    transaction_date: date
    description: str | None
    notes: str | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


# ══════════════════════════════════════════════════════════
#  FILTRY — query parametry dla GET /transactions
# ══════════════════════════════════════════════════════════

class TransactionFilters(BaseModel):
    """
    Używane przez router jako Depends() — Pydantic automatycznie
    waliduje query parametry i zwraca gotowy obiekt.
    """
    transaction_type: ExpenseIncome | None = None
    category_id: int | None = None
    date_from: date | None = None
    date_to: date | None = None
    min_amount: float | None = Field(None, gt=0)
    max_amount: float | None = Field(None, gt=0)

    @field_validator("date_to")
    @classmethod
    def date_to_after_date_from(cls, v, info):
        date_from = info.data.get("date_from")
        if v and date_from and v < date_from:
            raise ValueError("date_to nie może być wcześniejsze niż date_from")
        return v