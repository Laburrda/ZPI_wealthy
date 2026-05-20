from sqlalchemy import String, ForeignKey, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base

class BondDetails(Base):
    __tablename__: str = "bond_details"

    # Architecture Pattern - Join Table Inheritance 
    holding_id: Mapped[int] = mapped_column(
        ForeignKey("holdings.id", ondelete="CASCADE"),
        primary_key=True
    )

    # Attributes
    face_value: Mapped[float] = mapped_column(nullable=False)
    coupon_rate: Mapped[float] = mapped_column(nullable=True)
    maturity_date: Mapped[DateTime] = mapped_column(DateTime, nullable=False)
    issuer: Mapped[str] = mapped_column(String(150), nullable=False)

    # Relations
    holding: Mapped["Holding"] = relationship(back_populates="bond_details")