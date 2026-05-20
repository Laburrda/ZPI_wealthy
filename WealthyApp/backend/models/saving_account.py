from sqlalchemy import String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base

class SavingsAccount(Base):
    __tablename__: str = "savings_accounts"

    # Architecture Pattern - Join Table Inheritance 
    asset_id: Mapped[int] = mapped_column(
        ForeignKey("assets.id", ondelete="CASCADE"),
        primary_key=True
    )

    # Attributes
    institution_name: Mapped[str] = mapped_column(String(100), nullable=False)
    interest_rate: Mapped[float] = mapped_column(nullable=False)
    current_balance: Mapped[float] = mapped_column(nullable=False, server_default="0")
    balance_synced_at: Mapped[DateTime] = mapped_column(DateTime, nullable=True)

    # Relations
    asset: Mapped["Asset"] = relationship(back_populates="savings_account")