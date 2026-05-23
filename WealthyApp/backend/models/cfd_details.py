from sqlalchemy import  ForeignKey, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base

from enums import CFDDirection

class CFDDetails(Base):
    __tablename__: str = "cfd_details"

    # Architecture Pattern - Join Table Inheritance 
    holding_id: Mapped[int] = mapped_column(
        ForeignKey("holdings.id", ondelete="CASCADE"),
        primary_key=True
    )

    # Attributes
    leverage: Mapped[float] = mapped_column(nullable=False)
    margin_used: Mapped[float] = mapped_column(nullable=False)
    direction: Mapped[CFDDirection] = mapped_column(Enum(CFDDirection), nullable=False)

    # Relations
    holding: Mapped["Holding"] = relationship(back_populates="cfd_details")