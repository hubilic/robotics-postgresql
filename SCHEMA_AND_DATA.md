# Robotics schema and sample data

All base tables are in public. Week07 objects belong in the initially empty week07_lab schema. PK means primary key; FK means foreign key. Columns are required unless described as nullable. Exact DDL is in 01_setup.sql. All timestamps are UTC without timezone; costs are PLN.

## operators

id integer PK; name text; email text nullable; country char(2) nullable; registered_at timestamp; lifetime_cost numeric(14,2); deleted_at timestamp nullable.

Rows: 24.

## missions

id bigint PK; operator_id nullable FK operators; started_at timestamp; cost numeric(12,2) nonnegative; status nullable text: completed / queued / aborted.

Rows: 210.

## manufacturers

id integer PK; name text.

Rows: 6.

## robot_categories

id integer PK; name text; parent_id nullable FK robot_categories. Direct self-parenting prohibited.

Rows: 9.

## robot_models

id integer PK; manufacturer_id FK manufacturers; category_id nullable FK robot_categories; model_code unique text; name text; unit_cost numeric(10,2) nonnegative.

Rows: 12.

## mission_robots

mission_id FK missions; robot_model_id FK robot_models; robot_count positive integer; unit_cost nonnegative numeric(10,2). Composite PK(mission_id, robot_model_id).

Rows: 279.

## inspections

operator_id FK operators; robot_model_id FK robot_models; score required smallint 1-5; inspected_at timestamp. Composite PK(operator_id, robot_model_id).

Rows: 27.

## robot_inventory_morning

robot_model_id PK/FK robot_models; available_units nullable nonnegative integer.

Rows: 9.

## robot_inventory_evening

robot_model_id PK/FK robot_models; available_units nullable nonnegative integer.

Rows: 9.

## technical_documents

id integer PK; name text; published_at timestamp.

Rows: 12.

## tags

id integer PK; name unique text.

Rows: 8.

## document_tags

document_id FK technical_documents; tag_id FK tags. Composite PK(document_id,tag_id).

Rows: 24.

## operator_links

operator_id and partner_id FK operators; composite PK. Self-links prohibited; both directions are stored.

Rows: 24.

## robot_metrics

day date; metric text in sensor_reads / faults / missions; value nullable numeric(12,2). Composite PK(day,metric).

Rows: 16.

## sensor_readings

id integer PK; value nullable numeric.

Rows: 5.

## Deliberate edge cases

- 210 missions and 24 operators, including guest missions and NULL mission statuses.
- Operators 20 and 24 have no missions;24 registered in September. Operator 5 has missions but no completed mission. Operator 22 has only an April mission; 23 only an August mission.
- Operators 7, 8 and 23 have unknown country. Operators 1/2 and 7/8 are normalized contact duplicates within their countries.
- Operator contact strings include NULL, empty, ASCII-space-only, invalid at-sign counts, edge dots, repeated dots and embedded spaces.
- September 26 has no mission starts. September 1 midnight and September 30 23:59:59 boundaries are present. Missions 1001/1002 and 1005/1006 have tied start timestamps.
- Mission costs include 0,50,100,500,1000 and adjacent fractional values. The highest cost 1500 is tied on 1004 and 1007.
- Every mission cost reconciles to its deployment lines. Historical deployment costs differ from the current robot-model unit cost.
- Manufacturer 6 has no robot models. Model 12 has no deployment or inspection. Model names include literal underscore and percent characters.
- Inventory snapshots distinguish absent models, unknown counts, zero counts, and changed counts.
- Technical document 12 has no tags; tag 8 has no documents. Links for operator 1 include two-hop partners and shared direct partners.
- Robot metrics cover September 24-30 with a missing date, missing metric rows, genuine zero, and SQL NULL values.
- Sensor readings are 10, 20, NULL, 30, NULL.

## File conventions

The setup data is deterministic. HW7.8 generates random lab access codes as part of that exercise; code values vary across attempts, while their format and uniqueness checks remain fixed.
