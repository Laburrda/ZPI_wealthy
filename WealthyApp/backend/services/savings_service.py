from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status

from models.asset import Asset
from models.saving_account import SavingsAccount
from enums import AssetType
from schemas.asset import SavingsAccountCreate


def create_savings_account(
    db: Session,
    user_id: int,
    data: SavingsAccountCreate,
) -> SavingsAccount:
    """
    Tworzy ATOMOWO dwa rekordy: jeden w `assets` (wspólne pola),
    drugi w `savings_accounts` (specyficzne pola). Jeśli któryś
    INSERT się nie powiedzie, transakcja jest wycofywana - dzięki
    temu nie powstaje "osierocony" rekord w `assets`.
    """
    try:
        # KROK 1: utwórz wiersz w tabeli `assets`
        asset = Asset(
            user_id=user_id,
            asset_type=AssetType.SAVINGS,
            name=data.name,
            currency=data.currency,
        )
        db.add(asset)
        db.flush()  # wysyła INSERT do bazy, ale NIE commituje
                    # - dzięki temu `asset.id` jest już dostępne

        # KROK 2: utwórz wiersz w tabeli `savings_accounts`
        savings = SavingsAccount(
            asset_id=asset.id,
            institution_name=data.institution_name,
            interest_rate=data.interest_rate,
            current_balance=data.current_balance,
        )
        db.add(savings)
        db.commit()  # commit obu wstawek razem
        db.refresh(savings)  # przeładuj z bazy (m.in. server_defaults)
        return savings
    except Exception:
        db.rollback()
        raise  # propaguj wyjątek wyżej, router go obsłuży


def get_savings_account(
    db: Session,
    user_id: int,
    asset_id: int,
) -> SavingsAccount:
    """
    Pobiera konkretne konto oszczędnościowe DANEGO użytkownika.
    Filtrowanie po `user_id` jest WAŻNE - dzięki temu user A nie
    może pobrać konta usera B przez podanie cudzego asset_id.
    """
    savings = (
        db.query(SavingsAccount)
        .options(joinedload(SavingsAccount.asset))  # załaduj asset razem
        .join(Asset, Asset.id == SavingsAccount.asset_id)
        .filter(Asset.id == asset_id)
        .filter(Asset.user_id == user_id)
        .first()
    )
    if savings is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Konto oszczędnościowe o id={asset_id} nie znalezione.",
        )
    return savings


def list_savings_accounts(
    db: Session,
    user_id: int,
) -> list[SavingsAccount]:
    """Listuje wszystkie konta oszczędnościowe danego użytkownika."""
    return (
        db.query(SavingsAccount)
        .options(joinedload(SavingsAccount.asset))
        .join(Asset, Asset.id == SavingsAccount.asset_id)
        .filter(Asset.user_id == user_id)
        .all()
    )


def delete_savings_account(
    db: Session,
    user_id: int,
    asset_id: int,
) -> None:
    """
    Usuwa konto oszczędnościowe. Dzięki ON DELETE CASCADE w bazie
    usunięcie wiersza z `assets` automatycznie kasuje powiązany
    wiersz z `savings_accounts` - nie musimy tego robić ręcznie.
    """
    asset = (
        db.query(Asset)
        .filter(Asset.id == asset_id)
        .filter(Asset.user_id == user_id)
        .filter(Asset.asset_type == AssetType.SAVINGS)
        .first()
    )
    if asset is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Konto oszczędnościowe o id={asset_id} nie znalezione.",
        )
    db.delete(asset)
    db.commit()