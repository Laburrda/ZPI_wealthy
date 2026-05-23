from pydantic import BaseModel, ConfigDict, Field


# =========================================================
# ZUS
# =========================================================

class ZusProjectionRequest(BaseModel):
    """Parametry do symulacji przyszłej emerytury ZUS."""
    current_age: int = Field(
        ..., ge=18, le=80,
        description="Obecny wiek użytkownika.",
    )
    retirement_age: int = Field(
        ..., ge=60, le=80,
        description="Planowany wiek przejścia na emeryturę.",
    )
    monthly_gross_salary: float = Field(
        ..., gt=0,
        description="Aktualne wynagrodzenie BRUTTO miesięczne (PLN).",
    )
    accumulated_capital: float = Field(
        default=0.0, ge=0,
        description="Aktualnie zgromadzony kapitał na koncie ZUS (PLN). 0 = nie wiem.",
    )
    annual_salary_growth: float = Field(
        default=0.03, ge=0, le=0.20,
        description="Roczny wzrost wynagrodzenia (decimal). 0.03 = 3%/rok.",
    )
    annual_valorization: float = Field(
        default=0.05, ge=0, le=0.20,
        description="Roczna waloryzacja kapitału ZUS (decimal). 0.05 = 5%/rok.",
    )
    annual_inflation: float = Field(
        default=0.035, ge=0, le=0.20,
        description="Założona roczna inflacja - do obliczenia wartości realnej.",
    )


class ZusProjectionResponse(BaseModel):
    capital_at_retirement: float = Field(description="Zgromadzony kapitał ZUS w momencie emerytury (PLN, nominalnie).")
    monthly_pension_nominal: float = Field(description="Miesięczna emerytura nominalna w PLN przyszłych.")
    monthly_pension_real_today_value: float = Field(description="Miesięczna emerytura w sile nabywczej dzisiejszych PLN.")
    years_until_retirement: int
    life_expectancy_months_used: int = Field(description="Średnia dalsza długość życia w miesiącach (GUS, uproszczone).")
    disclaimer: str

    model_config = ConfigDict(from_attributes=True)


# =========================================================
# PRIVATE (4% rule)
# =========================================================

class PrivateProjectionRequest(BaseModel):
    """Parametry do symulacji prywatnego portfela emerytalnego."""
    current_portfolio_value: float = Field(
        ..., ge=0,
        description="Aktualna wartość prywatnego portfela (PLN, suma wszystkich kont/instrumentów).",
    )
    monthly_contribution: float = Field(
        ..., ge=0,
        description="Planowana miesięczna wpłata do portfela (PLN).",
    )
    years_to_retirement: int = Field(
        ..., ge=1, le=60,
        description="Liczba lat do planowanego przejścia na emeryturę.",
    )
    annual_return_rate: float = Field(
        default=0.06, ge=0, le=0.30,
        description="Oczekiwany roczny zwrot z portfela (decimal). 0.06 = 6% (typowo: zdywersyfikowany portfel akcyjno-obligacyjny).",
    )
    safe_withdrawal_rate: float = Field(
        default=0.04, ge=0.01, le=0.10,
        description="Bezpieczna stopa wypłaty rocznej z portfela. 0.04 = 4% rule (Trinity Study).",
    )


class PrivateProjectionResponse(BaseModel):
    portfolio_at_retirement: float = Field(description="Wartość portfela w momencie emerytury (PLN).")
    monthly_sustainable_income: float = Field(description="Miesięczny dochód możliwy do bezpiecznego wypłacania.")
    total_contributed: float = Field(description="Suma wszystkich wpłat (obecny portfel + miesięczne wpłaty × lata × 12).")
    total_growth_from_returns: float = Field(description="Zysk wygenerowany przez procent składany (portfolio - contributed).")
    years_until_retirement: int
    assumed_annual_return: float
    assumed_withdrawal_rate: float
    disclaimer: str

    model_config = ConfigDict(from_attributes=True)