from sqlalchemy import String, DateTime, ForeignKey, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from enums import IkeIkzeType

from database import Base

class IKEAccount(Base):
    __tablename__: str = "ike_accounts"

    # Architecture Pattern - Join Table Inheritance 
    asset_id: Mapped[int] = mapped_column(
        ForeignKey("assets.id", ondelete="CASCADE"),
        primary_key=True
    )

    # Attributes
    institution_name: Mapped[str] = mapped_column(String(100), nullable=False)
    account_subtype: Mapped[IkeIkzeType] = mapped_column(Enum(IkeIkzeType), nullable=False)
    annual_limit: Mapped[float] = mapped_column(nullable=False)
    annual_contributed: Mapped[float] = mapped_column(nullable=False, server_default="0")
    cash_balance: Mapped[float] = mapped_column(nullable=False)
    balance_updated_at: Mapped[DateTime] = mapped_column(DateTime, nullable=True)

    # Relations
    # TODO: confirm names in relations
    asset: Mapped["Asset"] = relationship(back_populates="ike_account")
    holdings: Mapped[list["Holding"]] = relationship(back_populates="ike_account")