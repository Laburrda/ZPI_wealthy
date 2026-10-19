# FinApp (ZPI_wealthy)

A mobile personal-finance assistant: one place to track savings, retirement accounts (IKE / IKZE / PPK),
stock-market investments, crypto, expenses and a retirement projection.
Built as a four-person university project (ZPI) with a FastAPI backend and a Flutter client.

**Stack:** Python 3.12 · FastAPI · SQLAlchemy 2 · Alembic · Pydantic v2 · JWT (python-jose) + bcrypt · SQLite · yfinance · Flutter (Dart) · Riverpod · Dio · fl_chart

> Team project. This is my fork, kept as a portfolio copy.

## What it does

- **Dashboard**: total net worth, allocation chart, monthly income/expense balance, top expense categories and alerts (e.g. IKE/IKZE annual limit reached)
- **Savings and retirement accounts**: savings accounts, PPK, IKE and IKZE (with annual contribution limits), crypto wallets
- **Investments**: stocks, ETFs, bonds and CFDs through a single endpoint with type-discriminated payloads; P&L per instrument; foreign-currency holdings converted to PLN
- **Live prices**: a background task refreshes prices (every 15 minutes) and FX rates (daily) from Yahoo Finance
- **Expenses**: transactions with categories (default and user-defined), filtering by type, category, date range and amount
- **Retirement calculator**: ZUS projection and private projection based on the 4% rule

## Architecture

```
Flutter client (Riverpod, Dio) ──HTTP/JSON, JWT──► FastAPI
                                                    ├── routers/     HTTP layer, dependency injection, auth guard
                                                    ├── services/    business logic (transactions, dashboard, holdings, retirement, price updater)
                                                    ├── schemas/     Pydantic v2 request/response models
                                                    ├── models/      SQLAlchemy 2 ORM models
                                                    └── alembic/     database migrations
```

Design notes:
- **Joined Table Inheritance** for assets: a shared `assets` table plus one table per subtype (`savings_accounts`, `ppk_accounts`, `ike_accounts`, `crypto_wallets`); holdings have their own detail tables for bonds and CFDs.
- **Discriminated unions** in Pydantic (`Union` + `Literal`) let one `POST /holdings/` endpoint validate stocks, ETFs, bonds and CFDs differently.
- **Per-user data isolation**: every query is scoped by the authenticated user's id; categories and IKE accounts are ownership-checked (403 on foreign resources).
- **Thin routers, logic in services**; the retirement calculator is a set of pure functions with no database access, so it is easy to unit-test.
- **Background tasks** started in the FastAPI lifespan handler; blocking `yfinance` calls run in an executor so they do not block the event loop; distinct tickers are fetched in one batch request.
- **Migrations** with Alembic (initial schema plus later changes: exchange-rate table, currency on holdings, nullable IKE link).
- **Seed script** (`scripts/seed_data.py`) fills the database with demo data for presentations.

Project documentation (plan, ERD, per-module docs, user stories) is in [`docs/`](docs).

## My role

Backend lead (Dev A in the project plan):
- backend architecture, project structure and SQLAlchemy 2 ORM models (joined-table inheritance for assets)
- Alembic setup and database migrations
- Pydantic v2 request/response schemas
- JWT authentication and CORS (registration, login, current-user dependency)
- transactions and categories module (CRUD, filtering)
- dashboard aggregation service and endpoint
- ERD and technical documentation

The asset CRUD endpoints, mock data and retirement calculator (backend) and the Flutter client were written by my teammates according to the roles in the plan.

## Running locally

### Backend

```bash
cd WealthyApp/backend
python -m venv .venv && source .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# put a random key into .env:  python -c "import secrets; print(secrets.token_hex(32))"
alembic upgrade head
python scripts/seed_data.py                            # optional demo data
uvicorn main:app --reload
```

Swagger UI: http://127.0.0.1:8000/docs. Demo account created by the seed script: `test@finapp.pl` / `Test1234!`.

Note: `main.py` currently sets the yfinance cache directory to `C:/temp/yfinance-cache`; on macOS and Linux change it to a directory that exists on your machine.

### Mobile client

```bash
cd finapp
flutter pub get
flutter run
```

The client uses `http://10.0.2.2:8000` on the Android emulator and `http://127.0.0.1:8000` elsewhere (see `lib/services/api_service.dart`).

## Known limitations and next steps

- **Money is stored as floating point** (`Float`). For a financial application, `Numeric` / `Decimal` is the right type, so this is the first thing I would change.
- **No automated backend tests yet.** Services take a session and a user id, and the retirement calculator is pure, so these are natural first targets for `pytest`.
- **Update (PUT) was cut from the MVP** for most asset types; the prototype supports create, read and delete.
- **CORS is open** (`*`) for development and should be restricted for any deployment.
- **SQLite** is used for the prototype; the schema is managed by Alembic, so moving to PostgreSQL is mostly a connection-string change plus a type review.
