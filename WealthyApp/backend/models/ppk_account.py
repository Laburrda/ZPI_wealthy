from sqlalchemy import String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base

class PPKAccount(Base):
    __tablename__: str = "ppk_accounts"

    # Architecture Pattern - Join Table Inheritance 
    asset_id: Mapped[int] = mapped_column(
        ForeignKey("assets.id", ondelete="CASCADE"),
        primary_key=True
    )

    # Attributes
    # TODO: come back to increment - should salary be included? how I can forecast the ppk acc in next years?
    institution_name: Mapped[str] = mapped_column(String(100), nulalble=False)
    fund_name: Mapped[str] = mapped_column(String(150), nullable=False)
    employee_rate: Mapped[float] = mapped_column(nulalble=False, server_default="2.0")
    employer_rate: Mapped[float] = mapped_column(nulalble=False, server_default="1.5")
    current_value: Mapped[float] = mapped_column(nulalble=False, server_default="0")
    value_updated_at: Mapped[DateTime] = mapped_column(DateTime, nullable=True)

    # Relations
    # TODO: confirm names in relations
    asset: Mapped["Asset"] = relationship(back_populates="ppk_accounts")