from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from enums import AssetClass, CFDDirection

# === SHARED BASE ===
class HoldingBase(BaseModel):
    ticker: str
    name: str
    quantity: float
    avg_purchase_price: float
    current_price: float = 0

# === CREATE SCHEMAS (per subtype) ===
class StockCreate(HoldingBase):

    asset_class: AssetClass = Field(default=AssetClass.STOCK, frozen=True)
    ike_account_id: int | None = None

class ETFCreate(HoldingBase):

    asset_class: AssetClass = Field(default=AssetClass.ETF, frozen=True)
    ike_account_id: int | None = None

class BondCreate(HoldingBase):

    asset_class: AssetClass = Field(default=AssetClass.BOND, frozen=True)
    ike_account_id: int | None = None

    # BondDetails Fields
    face_value: float
    coupon_rate: float | None = None
    maturity_date: datetime
    issuer: str

class CFDCreate(HoldingBase):

    asset_class: AssetClass = Field(default=AssetClass.CFD, frozen=True)
    ike_account_id: int | None = None

    # CFDDetails Fields
    leverage: float  # >1.0
    margin_used: float
    direction: CFDDirection

class CryptoCreate(HoldingBase):

    asset_class: AssetClass = Field(default=AssetClass.CRYPTO, frozen=True)
    ike_account_id: int | None = None

# === DISCRIMINATED UNION FOR CREATE ===
HoldingCreate = (
    StockCreate 
    | ETFCreate 
    | BondCreate 
    | CFDCreate 
    | CryptoCreate
)

# === RESPONSE SCHEMAS (per subtype) ===
class StockResponse(HoldingBase):

    id: int
    asset_class: AssetClass
    ike_account_id: int | None
    entry_date: datetime
    last_price_update: datetime | None
    
    model_config = ConfigDict(from_attributes=True)

class ETFResponse(HoldingBase):
    id: int
    asset_class: AssetClass
    ike_account_id: int | None
    entry_date: datetime
    last_price_update: datetime | None
    
    model_config = ConfigDict(from_attributes=True)

class BondResponse(HoldingBase):

    id: int
    asset_class: AssetClass
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
    asset_class: AssetClass
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
    asset_class: AssetClass
    ike_account_id: int | None
    entry_date: datetime
    last_price_update: datetime | None
    
    model_config = ConfigDict(from_attributes=True)

# === DISCRIMINATED UNION FOR RESPONSE ===
HoldingResponse = (
    StockResponse 
    | ETFResponse 
    | BondResponse 
    | CFDResponse 
    | CryptoResponse
)

# === UPDATE SCHEMAS ===
# TODO: Update schemas will be added later to not block DEV B - first prototype supports CREATE AND GET