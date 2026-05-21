# NOTE [DEV B]: zaktualizowane dyskryminatory unii (Literal types + Field(discriminator=...))
# Bez tego Swagger nie pokazywał pól specyficznych dla bond/cfd, a Pydantic
# po cichu dopasowywał WSZYSTKO do StockCreate (extra='ignore' defaultowy).
# DEV A: jeśli wolisz inny styl, daj znać przy review - można też zrobić Discriminator()
# z pydantic.types, ale ten zapis jest najbardziej rozpowszechniony w docs FastAPI.

from datetime import datetime
from typing import Annotated, Literal, Union

from pydantic import BaseModel, ConfigDict, Field

from enums import AssetClass, CFDDirection


# === SHARED BASE ===
class HoldingBase(BaseModel):
    ticker: str
    name: str
    quantity: float
    avg_purchase_price: float
    current_price: float = 0


# === CREATE SCHEMAS (per subtype) ===
# Literal[AssetClass.X] zamyka pole `asset_class` na DOKŁADNIE jedną wartość
# - to ten kawałek, który mówi Pydantic, jak rozróżniać warianty.

class StockCreate(HoldingBase):
    asset_class: Literal[AssetClass.STOCK] = AssetClass.STOCK
    ike_account_id: int | None = None

class ETFCreate(HoldingBase):
    asset_class: Literal[AssetClass.ETF] = AssetClass.ETF
    ike_account_id: int | None = None

class BondCreate(HoldingBase):
    asset_class: Literal[AssetClass.BOND] = AssetClass.BOND
    ike_account_id: int | None = None
    # BondDetails Fields
    face_value: float
    coupon_rate: float | None = None
    maturity_date: datetime
    issuer: str

class CFDCreate(HoldingBase):
    asset_class: Literal[AssetClass.CFD] = AssetClass.CFD
    ike_account_id: int | None = None
    # CFDDetails Fields
    leverage: float
    margin_used: float
    direction: CFDDirection

class CryptoCreate(HoldingBase):
    asset_class: Literal[AssetClass.CRYPTO] = AssetClass.CRYPTO
    ike_account_id: int | None = None


# === DISCRIMINATED UNION FOR CREATE ===
# Annotated[Union[...], Field(discriminator="asset_class")] mówi:
# "Patrz na pole asset_class w body i wybierz odpowiednią klasę".
# Swagger renderuje to jako dropdown z wyborem typu.
HoldingCreate = Annotated[
    Union[StockCreate, ETFCreate, BondCreate, CFDCreate, CryptoCreate],
    Field(discriminator="asset_class"),
]


# === RESPONSE SCHEMAS (per subtype) ===
class StockResponse(HoldingBase):
    id: int
    asset_class: Literal[AssetClass.STOCK] = AssetClass.STOCK
    ike_account_id: int | None
    entry_date: datetime
    last_price_update: datetime | None
    model_config = ConfigDict(from_attributes=True)

class ETFResponse(HoldingBase):
    id: int
    asset_class: Literal[AssetClass.ETF] = AssetClass.ETF
    ike_account_id: int | None
    entry_date: datetime
    last_price_update: datetime | None
    model_config = ConfigDict(from_attributes=True)

class BondResponse(HoldingBase):
    id: int
    asset_class: Literal[AssetClass.BOND] = AssetClass.BOND
    ike_account_id: int | None
    entry_date: datetime
    last_price_update: datetime | None
    # BondDetails Fields
    face_value: float
    coupon_rate: float | None
    maturity_date: datetime
    issuer: str
    model_config = ConfigDict(from_attributes=True)

class CFDResponse(HoldingBase):
    id: int
    asset_class: Literal[AssetClass.CFD] = AssetClass.CFD
    ike_account_id: int | None
    entry_date: datetime
    last_price_update: datetime | None
    # CFDDetails Fields
    leverage: float
    margin_used: float
    direction: CFDDirection
    model_config = ConfigDict(from_attributes=True)

class CryptoResponse(HoldingBase):
    id: int
    asset_class: Literal[AssetClass.CRYPTO] = AssetClass.CRYPTO
    ike_account_id: int | None
    entry_date: datetime
    last_price_update: datetime | None
    model_config = ConfigDict(from_attributes=True)


# === DISCRIMINATED UNION FOR RESPONSE ===
HoldingResponse = Annotated[
    Union[StockResponse, ETFResponse, BondResponse, CFDResponse, CryptoResponse],
    Field(discriminator="asset_class"),
]

# === UPDATE SCHEMAS ===
# TODO: Update schemas will be added later - first prototype supports CREATE AND GET