# Robotics PostgreSQL exercises

Four weekly worksheets in the same format as the supplied PDFs: plain white pages, the same typefaces, centered bold numbered headings, In-Class Exercises, and Homework Exercises. Each week has 10 in-class exercises and 10 homework exercises: **80 new tasks**.

Every scenario concerns robotics: operators, missions, robot models, manufacturers, inspections, inventory, technical documents, and sensor data. The SQL progression follows Weeks 06-09: SELECT/subqueries, DDL/DML, joins, and aggregation. The database preserves the relational patterns of the references while using robotics entities and new synthetic records.

## Start in your SQL application

1. Create a fresh database named `robotics_practice` using your normal database application's interface. Alternatively, run `00_create_database.sql` once while connected to another database, outside a transaction.
2. Connect your SQL editor to the new database and execute the entire `01_setup.sql` file.
3. Run `02_check_setup.sql`. It must complete without errors.
4. Open the appropriate PDF under `pdf/` and write your answers in `student_sql/`.
5. Open `answers/` after attempting the exercises. It contains complete solutions and expected query results.

The setup is atomic and refuses existing schema/table names. To reset, create another empty database and run setup there. Use a dedicated practice database.

## Shared rules

- Fixed exercise date: `DATE '2026-10-01'`; fixed reporting cutoff: `TIMESTAMP '2026-10-01 00:00:00'`.
- Timestamps represent UTC and use `timestamp without time zone`.
- Include range starts and exclude ends unless an exercise explicitly says otherwise.
- Costs are PLN. Completed cost sums only missions with `status = 'completed'`, attributed to `started_at`.
- Guest missions have NULL `operator_id`. A NULL status means unknown, distinct from queued or aborted.
- Each mission cost equals `SUM(mission_robots.robot_count * mission_robots.unit_cost)`. Mission lines preserve historical costs; `robot_models.unit_cost` is the current listed deployment cost per robot unit.
- `operators.lifetime_cost` stores the all-time sum of their completed mission costs. Guests belong to no operator balance.
- An inspection records an operator's assessment of a robot model and does not prove prior deployment.
- Operator links store both directions. Inventory NULL means unknown, while a missing row means absent from a snapshot.
- Week07 changes belong only in `week07_lab`. Execute each task inside `BEGIN;` and `ROLLBACK;` in the same editor connection. HW7.9 specifically requires this explicit transaction for deferred constraints. Each task uses its own table names.
- Reference queries in the other weeks read the public schema. Core methods follow the reference difficulty; homework introduces more demanding combinations and edge cases.

## Contents

- `pdf/`: four exercise sheets.
- `editable/`: editable Markdown versions.
- `student_sql/`: blank answer files.
- `answers/`: reference solutions and query results.
- `SCHEMA_AND_DATA.md`: exact database columns and seed details.
- `VALIDATION.md`: executed verification summary.

Scripts use PostgreSQL 17-compatible features and were executed on PostgreSQL 18.3. Version 17 was not separately tested.

Typography: [IBM Plex Sans by IBM](https://github.com/IBM/plex) and [iA Writer Mono by iA](https://github.com/iaolo/iA-Fonts), used to match the reference PDFs. Standalone font files are not included in this package.
