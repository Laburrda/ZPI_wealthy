import asyncio
import logging
from datetime import datetime, timezone

import yfinance as yf
from sqlalchemy.orm import Session

from database import SessionLocal   # fabryka sesji — nie get_db (to jest dla requestów)
from models.holding import Holding

from models.exchange_rate import ExchangeRate

# Logger — zamiast print(), bo w produkcji chcesz wiedzieć co i kiedy się stało
logger = logging.getLogger(__name__)


# ------------------------------------------------------------------ #
#  KROK 1: Pobierz unikalne tickery z bazy                           #
# ------------------------------------------------------------------ #

def _get_distinct_tickers(db: Session) -> list[str]:
    """
    SELECT DISTINCT ticker FROM holdings WHERE ticker IS NOT NULL.
    
    DISTINCT — bo 10 userów może mieć AAPL, nie ma sensu pobierać 10 razy.
    Jeden ticker = jeden rekord w odpowiedzi yfinance.
    """
    rows = (
        db.query(Holding.ticker)
        .filter(Holding.ticker.isnot(None))
        .distinct()
        .all()
    )
    # rows to lista tupli: [("AAPL",), ("MSFT",), ...]
    # dlatego r[0] — wyciągamy pierwszy (jedyny) element każdej tupli
    return [r[0] for r in rows]


# ------------------------------------------------------------------ #
#  KROK 2: Pobierz ceny z yfinance                                   #
# ------------------------------------------------------------------ #

def _fetch_prices(tickers: list[str]) -> dict[str, float]:
    """
    Zwraca słownik: {"AAPL": 189.50, "BTC-USD": 61200.0, ...}
    
    yf.download() to batch request — jeden HTTP call dla wszystkich tickerów.
    period="1d" oznacza dane z ostatniego dnia (interesuje nas tylko ostatnia cena).
    progress=False wyłącza pasek postępu w konsoli (niepotrzebny w tle).
    """
    if not tickers:
        return {}

    try:
        # Dla jednego tickera yf.download zwraca inną strukturę niż dla wielu —
        # group_by="ticker" wymusza spójny format niezależnie od liczby tickerów
        data = yf.download(
            tickers=tickers,
            period="1d",
            progress=False,
            group_by="ticker",
        )

        prices = {}
        for ticker in tickers:
            try:
                # data[ticker]["Close"] to seria pandas z cenami zamknięcia
                # .iloc[-1] — ostatni rekord (najnowsza cena)
                price = float(data[ticker]["Close"].iloc[-1])
                if price > 0:
                    prices[ticker] = price
            except (KeyError, IndexError):
                # KeyError: ticker nie istnieje w odpowiedzi (np. błędny symbol)
                # IndexError: seria pusta (brak danych dla tego okresu)
                logger.warning(f"Brak danych cenowych dla tickera: {ticker}")

        return prices

    except Exception as e:
        logger.error(f"yfinance batch download failed: {e}")
        return {}


# ------------------------------------------------------------------ #
#  KROK 3: Zaktualizuj ceny w bazie                                  #
# ------------------------------------------------------------------ #

def _update_prices_in_db(db: Session, prices: dict[str, float]) -> int:
    if not prices:
        return 0

    now = datetime.now(timezone.utc)
    updated_count = 0

    # Filtrujemy przed pętlą — jeśli yfinance zwrócił 0 lub None dla tickera,
    # pomijamy go całkowicie. Stara cena w bazie zostaje nieruszona.
    valid_prices = {
        ticker: price
        for ticker, price in prices.items()
        if price is not None and price > 0
    }

    if not valid_prices:
        logger.warning("Brak prawidłowych cen do zapisania — baza pozostaje niezmieniona.")
        return 0

    for ticker, price in valid_prices.items():
        count = (
            db.query(Holding)
            .filter(Holding.ticker == ticker)
            .update(
                {"current_price": price, "last_price_update": now},
                synchronize_session=False,
            )
        )
        updated_count += count

    db.commit()
    return updated_count


# ------------------------------------------------------------------ #
#  KROK 4: Orkiestrator — łączy kroki 1-3                           #
# ------------------------------------------------------------------ #

def run_price_update() -> None:
    """
    Synchroniczna funkcja wykonująca pełny cykl aktualizacji.
    Tworzy własną sesję DB — nie używa get_db() bo nie jesteśmy w kontekście requestu.
    
    Dlaczego własna sesja?
    get_db() to generator zaprojektowany dla FastAPI Depends —
    otwiera sesję, yield-uje, zamyka po requeście. Background task nie ma requestu,
    więc musimy zarządzać sesją ręcznie przez SessionLocal().
    """
    db = SessionLocal()
    try:
        tickers = _get_distinct_tickers(db)
        if not tickers:
            logger.info("Brak tickerów do aktualizacji.")
            return

        logger.info(f"Aktualizacja cen dla {len(tickers)} tickerów: {tickers}")

        prices = _fetch_prices(tickers)
        if not prices:
            logger.warning("yfinance nie zwrócił żadnych cen.")
            return

        count = _update_prices_in_db(db, prices)
        logger.info(f"Zaktualizowano {count} holdings. Ceny: {prices}")

    except Exception as e:
        logger.error(f"Błąd w run_price_update: {e}")
        db.rollback()
    finally:
        # finally — wykona się zawsze, nawet jeśli był wyjątek
        # gwarantuje że sesja zostanie zamknięta i nie wycieknie połączenie
        db.close()


# ------------------------------------------------------------------ #
#  KROK 5: Pętla asynchroniczna — serce background taska            #
# ------------------------------------------------------------------ #

async def price_update_loop(interval_seconds: int = 900) -> None:
    """
    Nieskończona pętla która co interval_seconds uruchamia aktualizację cen.
    
    Dlaczego asyncio.sleep a nie time.sleep?
    time.sleep() BLOKUJE cały wątek — FastAPI nie mógłby obsługiwać requestów
    podczas czekania. asyncio.sleep() tylko "zawiesza" tę korutynę i oddaje
    sterowanie event loop — inne korutyny (requesty) działają normalnie.
    
    asyncio.CancelledError — rzucane gdy task.cancel() zostanie wywołane
    przy zamknięciu aplikacji (w lifespan). Łapiemy je żeby pętla zakończyła się
    czysto zamiast logować fałszywy błąd.
    """
    logger.info("Price updater uruchomiony.")
    try:
        while True:
            # run_in_executor uruchamia SYNCHRONICZNĄ funkcję w osobnym wątku
            # bez blokowania event loop. Potrzebne bo yfinance i SQLAlchemy
            # są synchroniczne (używają blokujących operacji I/O).
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(None, run_price_update)

            logger.info(f"Następna aktualizacja cen za {interval_seconds // 60} min.")
            await asyncio.sleep(interval_seconds)

    except asyncio.CancelledError:
        logger.info("Price updater zatrzymany.")


# ------------------------------------------------------------------ #
#  Słownik par FX — jedno miejsce, łatwo rozszerzyć                 #
# ------------------------------------------------------------------ #

FX_TICKERS: dict[str, str] = {
    "USD": "USDPLN=X",
    "EUR": "EURPLN=X",
    "CHF": "CHFPLN=X",
    "GBP": "GBPPLN=X",
    "JPY": "JPYPLN=X",
    "CAD": "CADPLN=X",
}
# PLN → PLN = 1.0 zawsze, nie pobieramy z yfinance


# ------------------------------------------------------------------ #
#  FX KROK 1: Pobierz kursy z yfinance                              #
# ------------------------------------------------------------------ #

def _fetch_fx_rates() -> dict[str, float]:
    tickers = list(FX_TICKERS.values())

    try:
        data = yf.download(
            tickers=tickers,
            period="5d",
            progress=False,
            group_by="ticker",
            auto_adjust=True,
        )

        rates = {}
        for currency, ticker in FX_TICKERS.items():
            try:
                # MultiIndex: kolumny to tuple (ticker, field)
                # data[ticker]["Close"] działa tylko przy płaskim indeksie
                # data[(ticker, "Close")] działa zawsze przy MultiIndex
                series = data[(ticker, "Close")]
                # dropna() — pomija NaN (weekendy, święta)
                # iloc[-1] — ostatnia niepusta wartość
                series = series.dropna()
                if series.empty:
                    logger.warning(f"Brak danych FX dla {ticker} ({currency}) — pusta seria po dropna()")
                    continue
                rate = float(series.iloc[-1])
                if rate > 0:
                    rates[currency] = rate
                else:
                    logger.warning(f"Kurs {ticker} <= 0, pomijam.")
            except (KeyError, IndexError) as e:
                logger.warning(f"Brak danych FX dla {ticker} ({currency}): {e}")

        return rates

    except Exception as e:
        logger.error(f"yfinance FX download failed: {e}")
        return {}


# ------------------------------------------------------------------ #
#  FX KROK 2: Zapisz kursy do bazy (upsert)                         #
# ------------------------------------------------------------------ #

def _update_fx_in_db(db: Session, rates: dict[str, float]) -> int:
    """
    Upsert: aktualizuje istniejący rekord lub tworzy nowy.
    Nie nadpisuje kursu wartością 0 lub None — identyczna zasada
    jak w _update_prices_in_db() (better stale than wrong).
    """
    if not rates:
        return 0

    now = datetime.now(timezone.utc)
    updated_count = 0

    valid_rates = {
        currency: rate
        for currency, rate in rates.items()
        if rate is not None and rate > 0
    }

    if not valid_rates:
        logger.warning("Brak prawidłowych kursów FX — baza pozostaje niezmieniona.")
        return 0

    for currency, rate in valid_rates.items():
        record = (
            db.query(ExchangeRate)
            .filter_by(from_currency=currency, to_currency="PLN")
            .first()
        )
        if record:
            record.rate = rate
            record.updated_at = now
        else:
            db.add(ExchangeRate(
                from_currency=currency,
                to_currency="PLN",
                rate=rate,
                updated_at=now,
            ))
        updated_count += 1

    db.commit()
    return updated_count


# ------------------------------------------------------------------ #
#  FX KROK 3: Orkiestrator                                           #
# ------------------------------------------------------------------ #

def run_fx_update() -> None:
    """
    Pełny cykl aktualizacji kursów walut.
    Własna sesja DB — ten sam pattern co run_price_update().
    """
    db = SessionLocal()
    try:
        logger.info("Rozpoczynam aktualizację kursów FX.")
        rates = _fetch_fx_rates()

        if not rates:
            logger.warning("yfinance nie zwrócił żadnych kursów FX.")
            return

        count = _update_fx_in_db(db, rates)
        logger.info(f"Zaktualizowano {count} kursów FX: {rates}")

    except Exception as e:
        logger.error(f"Błąd w run_fx_update: {e}")
        db.rollback()
    finally:
        db.close()


# ------------------------------------------------------------------ #
#  FX KROK 4: Pętla asynchroniczna — raz dziennie                   #
# ------------------------------------------------------------------ #

async def fx_update_loop(interval_seconds: int = 86400) -> None:
    """
    Analogia do price_update_loop() — osobna pętla, osobna odpowiedzialność.
    Domyślny interwał: 86400s = 24h.

    Uruchamiana jest raz na start (przed pierwszym sleep) żeby tabela
    nie była pusta zanim minie pierwsza doba.
    """
    logger.info("FX updater uruchomiony.")
    try:
        while True:
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(None, run_fx_update)

            logger.info(f"Następna aktualizacja FX za {interval_seconds // 3600}h.")
            await asyncio.sleep(interval_seconds)

    except asyncio.CancelledError:
        logger.info("FX updater zatrzymany.")