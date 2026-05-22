import importlib
import pkgutil

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import auth, savings, ppk, ike_ikze, crypto, holdings

# Automatyczne ładowanie wszystkich modeli bazy danych na starcie aplikacji,
# aby zapobiec błędom relacji w SQLAlchemy (np. z brakiem klas User, PPKAccount itp.)
import models
for _, module_name, _ in pkgutil.iter_modules(models.__path__):
    importlib.import_module(f"models.{module_name}")


app = FastAPI(
    title="FinApp Backend",
    description="Backend dla aplikacji do zarządzania finansami osobistymi.",
    version="0.1.0",
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
# TODO: w miarę dodawania kolejnych typów aktywów (ppk, ike, ikze, crypto, holdings)
# i kalkulatora emerytalnego — dopisujemy kolejne include_router tutaj.
app.include_router(auth.router)
app.include_router(savings.router)
app.include_router(ppk.router)
app.include_router(ike_ikze.ike_router)
app.include_router(ike_ikze.ikze_router)
app.include_router(crypto.router)
app.include_router(holdings.router)