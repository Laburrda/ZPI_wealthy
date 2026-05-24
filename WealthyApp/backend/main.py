import importlib
import pkgutil

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import auth, savings, ppk, ike_ikze, crypto, holdings, retirement
from routers import dashboard

from routers.transactions import router as transactions_router
from routers.transactions import categories_router

# Automatyczne ładowanie wszystkich modeli bazy danych na starcie aplikacji,
# aby zapobiec błędom relacji w SQLAlchemy (np. z brakiem klas User, PPKAccount itp.)
import models
for _, module_name, _ in pkgutil.iter_modules(models.__path__):
    importlib.import_module(f"models.{module_name}")

import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI

from services.price_updater import price_update_loop, fx_update_loop

import yfinance as yf
yf.set_tz_cache_location("C:/temp/yfinance-cache")

# Konfiguracja loggera — zobaczysz logi price_updatera w konsoli
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # --- STARTUP ---
    price_task = asyncio.create_task(
        price_update_loop(interval_seconds=900)   # 15 minut
    )
    fx_task = asyncio.create_task(
        fx_update_loop(interval_seconds=86400)    # 24 godziny
    )

    yield  # aplikacja żyje tutaj

    # --- SHUTDOWN ---
    price_task.cancel()
    fx_task.cancel()
    try:
        await asyncio.gather(price_task, fx_task)
    except asyncio.CancelledError:
        pass

app = FastAPI(
    title="FinApp Backend",
    description="Backend dla aplikacji do zarządzania finansami osobistymi.",
    version="0.1.0",
    lifespan=lifespan
)

# === CORS ===
# Flutter (zwłaszcza emulator Android pod 10.0.2.2 i fizyczny telefon)
# musi mieć możliwość strzelania zapytań do tego API z innego origin.
# W produkcji ograniczamy listę — na prototyp puszczamy wszystko.
# TODO: DEV A może to potem przenieść/dopiąć pod auth.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# === HEALTH CHECK ===
@app.get("/", tags=["Health"])
def root():
    """Prosty endpoint do sprawdzenia, czy backend żyje."""
    return {"status": "ok", "service": "FinApp Backend", "version": "0.1.0"}


# === ROUTERY ===
app.include_router(auth.router)
app.include_router(savings.router)
app.include_router(ppk.router)
app.include_router(ike_ikze.ike_router)
app.include_router(ike_ikze.ikze_router)
app.include_router(crypto.router)
app.include_router(holdings.router)
app.include_router(retirement.router)
app.include_router(transactions_router)
app.include_router(categories_router)
app.include_router(dashboard.router)