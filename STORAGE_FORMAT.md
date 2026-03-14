# Storage Format Specification

This file describes the on-disk layout and file formats used by the Bash DBMS.

- Databases directory: `$DB_ROOT` (by default `./databases` in the package directory).
- Database path: `$DB_ROOT/<database_name>/`

Files per table:
- Metadata file: `<table_name>.meta`
  - Describes columns and types.
  - Format: each column separated by `|`. Each column is: `columnName:TYPE[:PK]`
    - Example header line: `id:int:PK|name:string|age:int`
  - Types supported (initial): `int`, `string`, `float`, `date`
- Data file: `<table_name>.data`
  - Each row stored as a single line.
  - Fields are separated by the delimiter `|` (pipe).
  - Example row: `1|Alice|30`
- Primary-key index file: `<table_name>.idx`
  - Stores primary-key values (one per line) for quick uniqueness checks.

Naming rules:
- Database and table names must match regex: `^[a-z][a-z0-9_]*$` (lowercase, numbers, underscores, start with a letter).
- Delimiter: `|` (pipe). Metadata uses the same delimiter for consistency.

Examples:
- Create database `school` → directory: `./databases/school/`
- Create table `students` with id PK and name:
  - `students.meta` content (one-line): `id:int:PK|name:string`
  - `students.data` after inserting one row: `1|Ahmed`
  - `students.idx` after inserting row: `1`

Notes:
- All paths are resolved relative to the DB root (`$DB_ROOT`) provided by `config.sh`.
- The storage format is intentionally simple to keep parsing straightforward in Bash.
