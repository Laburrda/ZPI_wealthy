from sqlalchemy import String, DateTime, Enum, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from database import Base

from enums import AssetType

class Asset(Base):
    __tablename__ = "assets"

    # Attributes
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    asset_type: Mapped[AssetType] = mapped_column(Enum(AssetType), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), server_default="PLN", nullable=False)
    created_at: Mapped[DateTime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[DateTime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    # Relations
    user: Mapped["User"] = relationship(back_populates="assets")
    savings_account: Mapped["SavingsAccount"] = relationship(back_populates="asset", uselist=False, cascade="all, delete-orphan")
    ppk_account: Mapped["PPKAccount"] = relationship(back_populates="asset", uselist=False, cascade="all, delete-orphan")
    ike_account: Mapped["IKEAccount"] = relationship(back_populates="asset", uselist=False, cascade="all, delete-orphan")
    crypto_wallet: Mapped["CryptoWallet"] = relationship(back_populates="asset", uselist=False, cascade="all, delete-orphan")