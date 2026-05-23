"""
retirement_service.py — kalkulator emerytalny.

Czyste funkcje, bez bazy danych. Logika matematyczna oddzielona
od warstwy HTTP - łatwo testować jednostkowo, łatwo używać z CLI.
"""

from fastapi import HTTPException, status

from schemas.retirement import (
    ZusProjectionRequest, ZusProjectionResponse,
    PrivateProjectionRequest, PrivateProjectionResponse,
)


# Stała ZUS - łączna składka na ubezpieczenie emerytalne (pracownik + pracodawca)
ZUS_CONTRIBUTION_RATE: float = 0.1952

# Tabela średniej dalszej długości życia w miesiącach
# Źródło: GUS (uśrednione dla obu płci, dane orientacyjne 2024)
# W realnym ZUS używa się aktualizowanej corocznie tablicy dla każdego wieku.
_LIFE_EXPECTANCY_MONTHS: dict[int, int] = {
    60: 252,
    62: 240,
    65: 217,
    67: 205,
    70: 185,
}


def _life_expectancy_months(retirement_age: int) -> int:
    """
    Zwraca przewidywaną dalszą długość życia w miesiącach dla danego wieku
    emerytalnego. Dla wieków pomiędzy wartościami w tabeli - liniowa interpolacja.
    """
    if retirement_age in _LIFE_EXPECTANCY_MONTHS:
        return _LIFE_EXPECTANCY_MONTHS[retirement_age]

    sorted_ages = sorted(_LIFE_EXPECTANCY_MONTHS.keys())
    if retirement_age <= sorted_ages[0]:
        return _LIFE_EXPECTANCY_MONTHS[sorted_ages[0]]
    if retirement_age >= sorted_ages[-1]:
        return _LIFE_EXPECTANCY_MONTHS[sorted_ages[-1]]

    # Liniowa interpolacja między najbliższymi punktami w tabeli
    for i in range(len(sorted_ages) - 1):
        a1, a2 = sorted_ages[i], sorted_ages[i + 1]
        if a1 < retirement_age < a2:
            v1, v2 = _LIFE_EXPECTANCY_MONTHS[a1], _LIFE_EXPECTANCY_MONTHS[a2]
            return int(v1 + (v2 - v1) * (retirement_age - a1) / (a2 - a1))
    return 210  # bezpieczny fallback


def calculate_zus_projection(data: ZusProjectionRequest) -> ZusProjectionResponse:
    """
    Symuluje przyszłą emeryturę z ZUS w uproszczeniu MVP.

    Algorytm:
    1. Co roku 19.52% wynagrodzenia brutto idzie na kapitał ZUS.
    2. Kapitał jest waloryzowany roczną stopą `annual_valorization`.
    3. Wynagrodzenie rośnie co roku o `annual_salary_growth`.
    4. Na emeryturze: kapitał_końcowy / średnia dalsza długość życia w miesiącach.
    5. Wartość realna = nominalna / (1 + inflacja)^lat.
    """
    if data.retirement_age <= data.current_age:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Wiek emerytalny musi być większy od obecnego.",
        )

    years_to_retirement = data.retirement_age - data.current_age

    capital = data.accumulated_capital
    salary = data.monthly_gross_salary

    # Iteracyjna symulacja rok po roku - czytelniej niż wzór analityczny
    # dla rosnących wpłat z waloryzacją.
    for _ in range(years_to_retirement):
        annual_contribution = salary * 12 * ZUS_CONTRIBUTION_RATE
        capital = (capital + annual_contribution) * (1 + data.annual_valorization)
        salary = salary * (1 + data.annual_salary_growth)

    life_months = _life_expectancy_months(data.retirement_age)
    monthly_pension_nominal = capital / life_months

    # Dyskontowanie inflacją - ile dzisiejszych złotych odpowiada przyszłej kwocie
    purchasing_power_factor = 1 / ((1 + data.annual_inflation) ** years_to_retirement)
    monthly_pension_real = monthly_pension_nominal * purchasing_power_factor

    return ZusProjectionResponse(
        capital_at_retirement=round(capital, 2),
        monthly_pension_nominal=round(monthly_pension_nominal, 2),
        monthly_pension_real_today_value=round(monthly_pension_real, 2),
        years_until_retirement=years_to_retirement,
        life_expectancy_months_used=life_months,
        disclaimer=(
            "Symulacja orientacyjna oparta na uproszczonym modelu. "
            "Rzeczywista emerytura ZUS zależy od wielu czynników "
            "(podział konto/subkonto, waloryzacja PKB, zmiany w prawie). "
            "Nie zastępuje oficjalnego kalkulatora ZUS."
        ),
    )


def calculate_private_projection(data: PrivateProjectionRequest) -> PrivateProjectionResponse:
    """
    Symuluje wartość prywatnego portfela emerytalnego metodą 4% rule.

    Algorytm:
    1. Future Value obecnego portfela (compound interest, kapitalizacja miesięczna).
    2. Plus Future Value miesięcznych wpłat (annuity, kapitalizacja miesięczna).
    3. Sustainable monthly income = portfolio_końcowe × safe_withdrawal_rate / 12.

    Kapitalizacja miesięczna daje bardziej realistyczny wynik niż roczna,
    bo wpłaty są miesięczne i każda dostaje swój czas na wzrost.
    """
    months = data.years_to_retirement * 12
    monthly_return = data.annual_return_rate / 12

    # FV obecnego portfela: PV × (1+r)^n, gdzie r to stopa miesięczna
    fv_current = data.current_portfolio_value * ((1 + monthly_return) ** months)

    # FV miesięcznych wpłat - wzór na annuity-future-value (wpłaty na koniec okresu)
    # Gdy stopa = 0, używamy sumy zwykłej (uniknięcie dzielenia przez 0)
    if monthly_return > 0:
        fv_contributions = data.monthly_contribution * (
            ((1 + monthly_return) ** months - 1) / monthly_return
        )
    else:
        fv_contributions = data.monthly_contribution * months

    portfolio_at_retirement = fv_current + fv_contributions

    # 4% rule (lub inna safe withdrawal rate) - roczna wypłata podzielona na 12 miesięcy
    monthly_sustainable = (portfolio_at_retirement * data.safe_withdrawal_rate) / 12

    # Statystyki: ile sam wpłacił, ile zyskał z procentu składanego
    total_contributed = data.current_portfolio_value + data.monthly_contribution * months
    total_growth = portfolio_at_retirement - total_contributed

    return PrivateProjectionResponse(
        portfolio_at_retirement=round(portfolio_at_retirement, 2),
        monthly_sustainable_income=round(monthly_sustainable, 2),
        total_contributed=round(total_contributed, 2),
        total_growth_from_returns=round(total_growth, 2),
        years_until_retirement=data.years_to_retirement,
        assumed_annual_return=data.annual_return_rate,
        assumed_withdrawal_rate=data.safe_withdrawal_rate,
        disclaimer=(
            "Symulacja oparta na założeniach stałego zwrotu i wpłat - "
            "rynki są zmienne. Reguła 4% (Trinity Study) zakłada portfel "
            "60/40 akcje/obligacje i 30-letni horyzont wypłat."
        ),
    )