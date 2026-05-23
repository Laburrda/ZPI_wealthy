from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base

from enums import ExpenseIncome


class Category(Base):
    __tablename__ = "categories"

    # Attributes
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=True)
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    transaction_type: Mapped[ExpenseIncome] = mapped_column(Enum(ExpenseIncome), nullable=False)
    icon: Mapped[str | None] = mapped_column(String(50), nullable=True)
    color: Mapped[str | None] = mapped_column(String(7), nullable=True)  # eg. "#FF5733"
    is_default: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, nullable=False)

    # Relations
    user = relationship("User", back_populates="categories")
    transactions = relationship("Transaction", back_populates="category")