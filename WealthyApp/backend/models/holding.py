from sqlalchemy import String, DateTime, Enum, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from database import Base

from enums import AssetClass

class Holding(Base):
    __tablename__: str = "holdings"

    # Attributes
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    ike_account_id: Mapped[int | None] = mapped_column(ForeignKey("ike_accounts.asset_id", ondelete="CASCADE"), nullable=False)
    ticker: Mapped[str] = mapped_column(String(20), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    asset_class: Mapped[AssetClass] = mapped_column(Enum(AssetClass), nullable=False)
    quantity: Mapped[float] = mapped_column(nullable=False)
    avg_purchase_price: Mapped[float] = mapped_column(nullable=False)
    current_price: Mapped[float] = mapped_column(nullable=False, server_default="0")
    entry_date: Mapped[DateTime] = mapped_column(DateTime, nullable=False, server_default=func.now())
    last_price_update: Mapped[DateTime] = mapped_column(DateTime, nullable=True)

    # Relations
    user: Mapped["User"] = relationship(back_populates="holdings")
    ike_account: Mapped["IKEAccount | None"] = relationship(back_populates="holdings")
    bond_details: Mapped["BondDetails"] = relationship(back_populates="holding", uselist=False)
    cfd_details: Mapped["CFDDetails"] = relationship(back_populates="holding", uselist=False)