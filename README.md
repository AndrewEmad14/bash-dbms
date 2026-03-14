# Bash DBMS — Documentation (Comprehensive)

This document describes the current state of the Bash DBMS, the on-disk
storage format, how the interactive flows work, and where to continue work.
It is written so collaborators can pick up and extend the project.

---

## Project layout (key files)

- `code/bash-dbms/`
  - `main.sh` — entry point and top-level menu (sources modules and runs `init_db`).
  - `config.sh` — configuration constants (paths, delimiter, file extensions).
  - `STORAGE_FORMAT.md` — authoritative on-disk format specification.
  - `helpers/dbValidations.sh` — validation helpers (name checks, type checks, index helpers, delimiter validation).
  - `db-crud/` — database-level operations:
    - `create-db.sh`, `list-db.sh`, `drop-db.sh`, `connect-db.sh`.
  - `table-crud/` — table-level operations:
    - `create-table.sh` — define columns and choose the primary key (required).
    - `list-tables.sh` — list tables in a database.
    - `insert-into-table.sh` — insert rows (user-provided PK, deferred input allowed).
    - `select-from-table.sh` — view rows (show all / filter by equality).
    - `tableMain.sh` — interactive table menu that sources the above scripts.

---

## Quick start (interactive)

1. Change to the package directory:

   ```bash
   cd code/bash-dbms
   ./main.sh
   ```

2. Use the top-level menu to create a database and connect to it. Inside the
   table menu you can create tables, insert rows, and view rows.

---

## Storage format (summary — see `STORAGE_FORMAT.md`)

- Database directory: `$DB_ROOT/<database_name>/` (default: `./databases/` inside the package).
- Table metadata: `<table>.meta` — a single header line listing columns in this format:
  `columnName:TYPE[:PK]` separated by the delimiter (pipe `|`). Exactly one `:PK` is required.
  Example: `id:int:PK|name:string|age:int`.
- Table data: `<table>.data` — each row on its own line, fields joined by `|`.
- Primary-key index: `<table>.idx` — one PK value per line (used to enforce uniqueness).

Naming rules: database/table/column names must match `^[a-z][a-z0-9_]*$`.

---

## Implemented features (current)

- Database-level: create, list, drop, connect. Files: `db-crud/*.sh`.
- Table-level: create table (columns + required PK), list tables.
- Data operations: insert rows (with validation and PK uniqueness) and select rows
  (show all, or filter by `column == value`).
- Utilities: `config.sh` to centralize paths; `helpers/dbValidations.sh` for
  common validation routines.

---

## Detailed flows (for collaborators)

### Create Table

- Run `Create Table` in the table menu (or call `createTable <db_name>`).
- Flow:
  1. Enter table name (validated).
  2. Enter number of columns (positive integer).
  3. For each column enter a unique column name and a type (allowed: `int`, `string`, `float`, `date`).
  4. After entering all columns you MUST choose exactly one primary key column
     (by number or column name). The script will re-prompt until a valid choice
     is provided.
  5. You confirm the final schema. On confirmation the following files are created:
     - `<table>.meta` — schema header (contains exactly one `:PK`).
     - `<table>.data` — empty data file.
     - `<table>.idx` — empty PK index file.

Rationale: requiring exactly one PK keeps index logic simple and preserves
integrity for insert/delete/update operations.

### Insert Into Table

- Run `Insert Into Table` in the table menu (or `insertIntoTable <db_name>`).
- Flow and rules:
  - The script reads the table `.meta` to learn column order and types.
  - It prompts for each column value in schema order. For the PK column the
    prompt allows deferring (press Enter). The script will always require and
    validate the PK before saving the row.
  - Validations applied before persisting the row:
    - All provided values are validated against their declared type.
    - Values are rejected if they contain the field delimiter (`|`) — this is
      validated by `helpers/dbValidations.sh:validateNoDelimiter`.
    - The PK must be present, must match its declared type, and must be unique
      (checked against `<table>.idx`).
  - On success:
    - Append the joined row to `<table>.data` (fields joined by `|`).
    - Append the PK value to `<table>.idx`.

Notes:
- Primary keys are NOT auto-incremented — the user must supply them.
- The `.idx` file is used to prevent duplicates; it must be kept in sync by
  delete/update operations (not implemented yet).

### Select From Table

- Run `Select From Table` in the table menu (`selectFromTable <db_name>`).
- Options:
  - Show all rows: prints a header line (column names) then all rows.
  - Filter (WHERE column = value): choose a column (number or name), provide a
    value (validated against that column's type), and the script returns rows
    where the column equals the provided value.
- Output is plain text rows with the same delimiter `|` between fields.

Limitations: only simple equality filters are supported; no SQL parsing yet.

---

## Validation helpers (where to look)

`code/bash-dbms/helpers/dbValidations.sh` provides exported functions used by
scripts. Important helpers include:

- `validateName(value)` — checks identifier naming rules.
- `validateValueByType(value, type)` — checks `int`, `float`, `date`, `string`.
- `validateNoDelimiter(value)` — rejects input containing `DELIM` (the `|`).
- `isPrimaryKeyUnique(db, table, value)` — checks `<table>.idx` for duplicates.
- `ensureIndexFile(db, table)` — creates `.idx` if missing.
- `validate_meta_file(path)` — ensures `.meta` header is valid and has exactly one PK.
- `trim(value)` — trims whitespace.

If you add logic that accepts user input, call `validateNoDelimiter` to avoid
breaking the on-disk format.

---

## Non-interactive examples / smoke test

You can run the following sequence to verify core functionality (create DB,
create table, insert rows, select rows). Run these from the repository root:

```bash
# 1) Create a test DB
bash -c "source code/bash-dbms/config.sh; source code/bash-dbms/db-crud/create-db.sh; createDatabase" <<'DB'
test_smoke
DB

# 2) Create table 'students' with id PK
bash -c "source code/bash-dbms/config.sh; source code/bash-dbms/table-crud/create-table.sh; createTable test_smoke" <<'TB'
students
3
id
int
name
string
age
int
id
y
TB

# 3) Insert two rows (first uses PK at column prompt, second defers PK and supplies it at the end)
bash -c "source code/bash-dbms/config.sh; source code/bash-dbms/table-crud/insert-into-table.sh; insertIntoTable test_smoke" <<'I1'
students
1
Alice
30
I1

bash -c "source code/bash-dbms/config.sh; source code/bash-dbms/table-crud/insert-into-table.sh; insertIntoTable test_smoke" <<'I2'
students

Bob
25
2
I2

# 4) Select all rows
bash -c "source code/bash-dbms/config.sh; source code/bash-dbms/table-crud/select-from-table.sh; selectFromTable test_smoke" <<'S1'
students
1
S1

# 5) Filter rows (name == Bob)
bash -c "source code/bash-dbms/config.sh; source code/bash-dbms/table-crud/select-from-table.sh; selectFromTable test_smoke" <<'S2'
students
2
name
Bob
S2
```

Expected outputs: header line then two rows, and the filtered run should return
only Bob's row.

---

## Developer notes / next work

Recommended next tasks for contributors:
- Implement `drop-table` with safe confirmation and cleanup of `.meta`, `.data`, `.idx`.
- Implement `delete-from-table` and `update-table` and ensure `.idx` is updated on
  PK changes or row deletions.
- Add escaping/quoting for delimiter if you want to allow `|` inside values (requires
  read/write escaping everywhere).
- Add automated tests under `tests/` to protect against regressions.

Coding conventions:
- Source `config.sh` in every script and use `DB_ROOT` and `DELIM` constants rather than hard-coded paths.
- Put reusable validations in `helpers/dbValidations.sh`.

---

If you'd like I can also add a small `scripts/smoke_test.sh` that runs the
non-interactive example above and returns a non-zero exit code on failures —
useful to run locally before pushing.

