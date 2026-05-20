import enum

class AssetClass(str, enum.Enum):
    STOCK = "stock"
    ETF = "etf"
    BOND = "bond"
    CFD = "cfd"
    CRYPTO = "crypto"