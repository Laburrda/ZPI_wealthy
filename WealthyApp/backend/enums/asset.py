import enum

class AssetType(str, enum.Enum):
    SAVINGS = "savings"
    PPK = "ppk"
    IKE = "ike"
    IKZE = "ikze"
    CRYPTO = "crypto"