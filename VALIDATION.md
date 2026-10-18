# Validation

Executed on an isolated PostgreSQL 18.3 instance. PostgreSQL 17-compatible syntax is used; version17 was not separately run.

All 80 reference solutions executed successfully (60 read-only queries and20 DDL/DML exercises). Every Week07 block ran in its own transaction and was rolled back.

- Every mission total equals its historical robot deployment lines.
- Operator chronology and all stored lifetime completed costs agree with missions.
- Empty-day, literal pattern-matching and symmetric operator-link fixtures are present.
- IC9.2 counts are independently reproduced from mission records.
- IC9.7 medians match independently sorted observations, including repeated costs.
- IC9.8 all 30 calendar dates and running costs match an independent cumulative sum.
- HW9.1 NULL-sensitive sensor aggregates equal hand-calculated values.
- HW9.4 historical robot deployment lines reconcile model totals with mission costs.
- HW9.9 all hourly buckets, guest counts and final-second mission boundaries agree.
- HW9.10 cohort sizes, distinct active operators and observation cutoffs agree.
- All Week07 exercises roll back without changing any base row.
- Setup refuses existing objects atomically and preserves the seed.

## Table counts

| Table | Rows |
|---|---:|
| operators | 24 |
| missions | 210 |
| manufacturers | 6 |
| robot_categories | 9 |
| robot_models | 12 |
| mission_robots | 279 |
| inspections | 27 |
| robot_inventory_morning | 9 |
| robot_inventory_evening | 9 |
| technical_documents | 12 |
| tags | 8 |
| document_tags | 24 |
| operator_links | 24 |
| robot_metrics | 16 |
| sensor_readings | 5 |

## Query result counts

| Exercise | Rows |
|---|---:|
| IC6.1 | 14 |
| IC6.2 | 5 |
| IC6.3 | 24 |
| IC6.4 | 15 |
| IC6.5 | 4 |
| IC6.6 | 210 |
| IC6.7 | 71 |
| IC6.8 | 22 |
| IC6.9 | 10 |
| IC6.10 | 19 |
| HW6.1 | 14 |
| HW6.2 | 5 |
| HW6.3 | 24 |
| HW6.4 | 24 |
| HW6.5 | 35 |
| HW6.6 | 1 |
| HW6.7 | 2 |
| HW6.8 | 24 |
| HW6.9 | 6 |
| HW6.10 | 7 |
| IC8.1 | 17 |
| IC8.2 | 76 |
| IC8.3 | 8 |
| IC8.4 | 9 |
| IC8.5 | 24 |
| IC8.6 | 7 |
| IC8.7 | 168 |
| IC8.8 | 24 |
| IC8.9 | 12 |
| IC8.10 | 6 |
| HW8.1 | 24 |
| HW8.2 | 1 |
| HW8.3 | 118 |
| HW8.4 | 5 |
| HW8.5 | 6 |
| HW8.6 | 4 |
| HW8.7 | 19 |
| HW8.8 | 41 |
| HW8.9 | 2 |
| HW8.10 | 5 |
| IC9.1 | 21 |
| IC9.2 | 1 |
| IC9.3 | 3 |
| IC9.4 | 22 |
| IC9.5 | 24 |
| IC9.6 | 5 |
| IC9.7 | 24 |
| IC9.8 | 30 |
| IC9.9 | 36 |
| IC9.10 | 7 |
| HW9.1 | 1 |
| HW9.2 | 16 |
| HW9.3 | 24 |
| HW9.4 | 12 |
| HW9.5 | 5 |
| HW9.6 | 1 |
| HW9.7 | 7 |
| HW9.8 | 38 |
| HW9.9 | 24 |
| HW9.10 | 25 |
