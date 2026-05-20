from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from enums import AssetType, IkeIkzeType

# === SHARED BASE ===
class AssetBase(BaseModel):
    name: str
    currency: str = "PLN"

# === CREATE SCHEMAS (per subtype) ===
class SavingsAccountCreate(AssetBase):
    asset_type: AssetType = Field(default=AssetType.SAVINGS, frozen=True)
    institution_name: str
    interest_rate: float
    current_balance: float = 0

class PPKAccountCreate(AssetBase):
    asset_type: AssetType = Field(default=AssetType.PPK, frozen=True)
    institution_name: str
    fund_name: str
    employee_rate: float = 2.0
    employer_rate: float = 1.5
    current_value: float = 0

class IKEAccountCreate(AssetBase):
    asset_type: AssetType = Field(default=AssetType.IKE, frozen=True)
    account_subtype: IkeIkzeType = Field(default=IkeIkzeType.IKE, frozen=True)
    institution_name: str
    annual_limit: float
    annual_contributed: float = 0
    cash_balance: float = 0

class IKZEAccountCreate(AssetBase):
    asset_type: AssetType = Field(default=AssetType.IKZE, frozen=True)
    account_subtype: IkeIkzeType = Field(default=IkeIkzeType.IKZE, frozen=True)
    institution_name: str
    annual_limit: float
    annual_contributed: float = 0
    cash_balance: float = 0

class CryptoWalletCreate(AssetBase):
    asset_type: AssetType = Field(default=AssetType.CRYPTO, frozen=True)
    institution_name: str
    wallet_address: str
    current_value: float = 0

# === DISCRIMINATED UNION FOR CREATE ===
AssetCreate = (
    SavingsAccountCreate 
    | PPKAccountCreate 
    | IKEAccountCreate 
    | IKZEAccountCreate 
    | CryptoWalletCreate
)

# === RESPONSE SCHEMAS (per subtype) ===
class SavingsAccountResponse(AssetBase):
    id: int
    asset_type: AssetType
    institution_name: str
    interest_rate: float
    current_balance: float
    balance_synced_at: datetime | None
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

class PPKAccountResponse(AssetBase):
    id: int
    asset_type: AssetType
    institution_name: str
    fund_name: str
    employee_rate: float
    employer_rate: float
    current_value: float
    value_updated_at: datetime | None
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

class IKEAccountResponse(AssetBase):
    id: int
    asset_type: AssetType
    account_subtype: IkeIkzeType
    institution_name: str
    annual_limit: float
    annual_contributed: float
    cash_balance: float
    balance_synced_at: datetime | None
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

# IKZE używa tego samego response schema co IKE - różnica tylko w account_subtype
IKZEAccountResponse = IKEAccountResponse

class CryptoWalletResponse(AssetBase):
    id: int
    asset_type: AssetType
    institution_name: str
    wallet_address: str
    current_value: float
    value_updated_at: datetime | None
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

# === DISCRIMINATED UNION FOR RESPONSE ===
AssetResponse = (
    SavingsAccountResponse 
    | PPKAccountResponse 
    | IKEAccountResponse 
    | IKZEAccountResponse 
    | CryptoWalletResponse
)

# === UPDATE SCHEMAS ===
# TODO: Update schemas will be added later to not block DEV B - first prototype supports CREATE AND GET