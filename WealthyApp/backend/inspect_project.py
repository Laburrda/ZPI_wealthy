"""
FinApp — skrypt diagnostyczny struktury projektu
Uruchom z głównego folderu backendu: python inspect_project.py
"""
 
import os
import sys
import ast
import importlib.util
from pathlib import Path
 
# ── kolory terminala ──────────────────────────────────────────────────────────
GREEN  = "\033[92m"
YELLOW = "\033[93m"
RED    = "\033[91m"
CYAN   = "\033[96m"
BOLD   = "\033[1m"
RESET  = "\033[0m"
 
def h(text): print(f"\n{BOLD}{CYAN}{'─'*60}{RESET}\n{BOLD}{text}{RESET}")
def ok(text): print(f"  {GREEN}✓{RESET}  {text}")
def warn(text): print(f"  {YELLOW}⚠{RESET}  {text}")
def err(text): print(f"  {RED}✗{RESET}  {text}")
def info(text): print(f"     {text}")
 
# ── 1. STRUKTURA FOLDERÓW ─────────────────────────────────────────────────────
h("1. STRUKTURA FOLDERÓW")
 
important_dirs  = ["models", "schemas", "routers", "services", "migrations", "alembic"]
important_files = ["main.py", "database.py", "requirements.txt", ".env", "alembic.ini",
                   "mock_data.py", "seed_data.py"]
 
for d in important_dirs:
    if Path(d).is_dir():
        files = list(Path(d).glob("*.py"))
        ok(f"{d}/  ({len(files)} plików .py)")
        for f in sorted(files):
            info(f"  {f.name}")
    else:
        warn(f"{d}/  — brak folderu")
 
print()
for f in important_files:
    if Path(f).exists():
        size = Path(f).stat().st_size
        ok(f"{f}  ({size} B)")
    else:
        warn(f"{f}  — brak pliku")
 
# ── 2. MODELE SQLALCHEMY ──────────────────────────────────────────────────────
h("2. MODELE SQLALCHEMY — klasy i tabele")
 
def extract_classes_from_file(filepath):
    """Parsuje plik .py i zwraca nazwy klas oraz wartości __tablename__."""
    try:
        source = Path(filepath).read_text(encoding="utf-8")
        tree   = ast.parse(source)
    except Exception as e:
        return [], str(e)
 
    results = []
    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef):
            tablename = None
            columns   = []
            for item in node.body:
                # szukamy __tablename__ = "..."
                if isinstance(item, ast.Assign):
                    for target in item.targets:
                        if isinstance(target, ast.Name) and target.id == "__tablename__":
                            if isinstance(item.value, ast.Constant):
                                tablename = item.value.value
                # szukamy pól mapped_column / Column
                if isinstance(item, ast.AnnAssign) and isinstance(item.target, ast.Name):
                    columns.append(item.target.id)
            results.append({
                "class":     node.name,
                "tablename": tablename,
                "columns":   columns,
            })
    return results, None
 
models_dir = Path("models")
if models_dir.exists():
    all_tables = []
    for py_file in sorted(models_dir.glob("*.py")):
        if py_file.name == "__init__.py":
            continue
        classes, parse_err = extract_classes_from_file(py_file)
        if parse_err:
            err(f"{py_file.name}  — błąd parsowania: {parse_err}")
            continue
        for cls in classes:
            if cls["tablename"]:  # pomijamy klasy pomocnicze bez __tablename__
                ok(f"class {cls['class']}  →  tabela '{cls['tablename']}'  ({py_file.name})")
                if cls["columns"]:
                    info(f"  pola: {', '.join(cls['columns'])}")
                all_tables.append(cls["tablename"])
 
    print()
    missing = [t for t in ["transactions", "categories"] if t not in all_tables]
    if missing:
        warn(f"BRAKUJĄCE tabele (do dodania w Sesji 4): {', '.join(missing)}")
    else:
        ok("Wszystkie tabele Sesji 4 już istnieją")
else:
    err("Brak folderu models/ — uruchom skrypt z głównego folderu backendu")
 
# ── 3. SCHEMATY PYDANTIC ──────────────────────────────────────────────────────
h("3. SCHEMATY PYDANTIC")
 
schemas_dir = Path("schemas")
if schemas_dir.exists():
    for py_file in sorted(schemas_dir.glob("*.py")):
        if py_file.name == "__init__.py":
            continue
        classes, _ = extract_classes_from_file(py_file)
        names = [c["class"] for c in classes]
        ok(f"{py_file.name}:  {', '.join(names) if names else '(brak klas)'}")
else:
    warn("Brak folderu schemas/")
 
# ── 4. ROUTERY FASTAPI ────────────────────────────────────────────────────────
h("4. ROUTERY FASTAPI")
 
routers_dir = Path("routers")
if routers_dir.exists():
    for py_file in sorted(routers_dir.glob("*.py")):
        if py_file.name == "__init__.py":
            continue
        try:
            source = Path(py_file).read_text(encoding="utf-8")
            tree   = ast.parse(source)
            routes = []
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef) or isinstance(node, ast.AsyncFunctionDef):
                    for decorator in node.decorator_list:
                        if isinstance(decorator, ast.Call):
                            func = decorator.func
                            method = ""
                            if isinstance(func, ast.Attribute):
                                method = func.attr.upper()
                            elif isinstance(func, ast.Name):
                                method = func.id.upper()
                            if method in ("GET", "POST", "PUT", "DELETE", "PATCH"):
                                path_arg = ""
                                if decorator.args:
                                    a = decorator.args[0]
                                    if isinstance(a, ast.Constant):
                                        path_arg = a.value
                                routes.append(f"{method} {path_arg}")
            ok(f"{py_file.name}:")
            for r in routes:
                info(f"  {r}")
            if not routes:
                info("  (brak zdefiniowanych endpointów)")
        except Exception as e:
            warn(f"{py_file.name}  — błąd: {e}")
else:
    warn("Brak folderu routers/")
 
# ── 5. WERSJE PACZEK ──────────────────────────────────────────────────────────
h("5. REQUIREMENTS.TXT — kluczowe paczki")
 
req_file = Path("requirements.txt")
if req_file.exists():
    lines = req_file.read_text().splitlines()
    key   = ["fastapi", "sqlalchemy", "alembic", "pydantic", "bcrypt",
             "python-jose", "passlib", "uvicorn", "apscheduler", "yfinance"]
    for line in lines:
        low = line.lower()
        if any(k in low for k in key):
            ok(line.strip())
        else:
            info(line.strip())
else:
    warn("Brak requirements.txt")
 
# ── 6. MIGRACJE ALEMBIC ───────────────────────────────────────────────────────
h("6. MIGRACJE ALEMBIC")
 
versions_dir = Path("migrations/versions")
if not versions_dir.exists():
    versions_dir = Path("alembic/versions")
 
if versions_dir.exists():
    migrations = sorted(versions_dir.glob("*.py"))
    ok(f"Znaleziono {len(migrations)} migracji:")
    for m in migrations[-5:]:  # ostatnie 5
        # wyciągnij revision i down_revision z pliku
        try:
            source = m.read_text(encoding="utf-8")
            rev = down = "?"
            for line in source.splitlines():
                if line.startswith("revision"):
                    rev  = line.split("=")[1].strip().strip('"\'')
                if line.startswith("down_revision"):
                    down = line.split("=")[1].strip().strip('"\'')
            info(f"  {m.name}  rev={rev}  down={down}")
        except:
            info(f"  {m.name}")
else:
    warn("Brak folderu migrations/versions — alembic nie był jeszcze uruchamiany?")
 
# ── PODSUMOWANIE ──────────────────────────────────────────────────────────────
h("PODSUMOWANIE — co zrobić dalej (Dev A, Sesja 4)")
print(f"""
  {BOLD}Do zrobienia:{RESET}
  1. Dodaj models/category.py       — model Category (tabela categories)
  2. Dodaj models/transaction.py    — model Transaction (tabela transactions)
  3. Zarejestruj oba modele w env.py alembic (lub env używa Base.metadata)
  4. alembic revision --autogenerate -m "add_transactions_categories"
  5. alembic upgrade head
  6. Dodaj schemas/transaction.py   — Pydantic schemas
  7. Dodaj routers/transactions.py  — CRUD + filtrowanie
  8. Podepnij router w main.py
""")