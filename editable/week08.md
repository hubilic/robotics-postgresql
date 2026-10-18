# WEEK 8 -- SQL: JOINs and Relational Queries

**Setup:** Use the robotics database from 01_setup.sql. Today is 2026-10-01; timestamps are UTC and costs are PLN. Use historical mission_robots.unit_cost for deployment costs. Do not use window functions.

## 1. In-Class Exercises

### 1.1. IC8.1 -- A mission review list with guest operators

Join September missions to operators and list missions whose status is queued or SQL NULL. Return mission id, operator name, country, and cost, ordered by mission id. Preserve guest missions with NULL operator fields; explain which rows an INNER JOIN would remove and why a LEFT JOIN fits this report.


### 1.2. IC8.2 -- Historical deployment rates versus current rates

Find September mission-model rows whose historical unit_cost differs from the model's current unit_cost. Join missions, mission_robots, robot_models, and manufacturers; include every mission status. Show mission id, model name, manufacturer name, robot_count, historical and current unit costs, and historical deployment cost. Order by mission id then model id; historical deployment cost uses robot_count multiplied by the mission's unit_cost.


### 1.3. IC8.3 -- Operators without a September completion

Use a LEFT JOIN anti join to find operators with no completed mission started in September, including those with no missions at all. Return operator id and name once, ordered by id. Keep completion and date conditions in ON, and test an unmatched mission primary key rather than a nullable status or operator field.


### 1.4. IC8.4 -- Two levels of robot category ancestry

List every robot category with its immediate parent name and grandparent name using two self joins. Return category id, category_name, parent_name, and grandparent_name, ordered by category id. Keep root categories and categories with only one ancestor, using SQL NULL for each missing level; do not use a recursive query.


### 1.5. IC8.5 -- The first fourteen days of operator activity

For every operator registered before 2026-10-01, show missions started from registration inclusive to registration plus 14 days exclusive, also before the cutoff. Return operator id, name, mission id, and started_at. Preserve operators with no matches as one NULL-mission row; place mission filters in ON and sort by operator id, timestamp NULLS LAST, then mission id.


### 1.6. IC8.6 -- Fleet availability changes with unknown counts

FULL JOIN morning and evening robot inventory by robot_model_id. Return models appearing in only one snapshot or with different available_units, including NULL-to-zero changes; two NULL counts are unchanged. Show robot_model_id, morning_units, evening_units, and change_type: added, removed, or changed. Determine presence from model id, preserve NULL counts, and order by model id.


### 1.7. IC8.7 -- An operator calendar from registration onward

Build an operator-by-day grid for September 24–30, keeping only dates on or after each operator's registration calendar date. LEFT JOIN completed missions into each half-open daily start-time bucket. Return operator_id, activity_day, completed_mission_count, and completed_cost_pln, with zeros for empty cells. Include every operator eligible for a grid cell and order by operator id and day.


### 1.8. IC8.8 -- The latest completed mission per operator

Use LEFT JOIN LATERAL to attach each operator's completed mission with the latest started_at before 2026-10-01. If start timestamps tie, choose the larger mission id. Return operator id, name, mission id, started_at, and cost, ordered by operator id. Keep operators without a qualifying mission with NULL mission fields, without window functions.


### 1.9. IC8.9 -- Technical document labels without missing documents

Return every technical document's id and name together with tag_count and a comma-separated list of tag names in alphabetical order. Untagged documents must remain with count zero and an empty string, not SQL NULL. Use document_tags and LEFT JOINs; order documents by id and avoid counting the synthetic unmatched row.


### 1.10. IC8.10 -- Manufacturer deployment totals at the right grain

For every manufacturer, show id, name, model_count, robots_deployed, and completed_cost_pln for September missions. Count all its robot models, including unused ones; sum robot_count and historical deployment costs only for completed missions. Include manufacturers with no models or deployments using zeros. Prevent repeated deployment rows from inflating model counts, and order by manufacturer id.


## 2. Homework Exercises

### 2.1. HW8.1 -- A four-state operator mission profile

Return every operator's id and September counts for completed, queued, aborted, and unknown statuses, plus total_missions and completed_cost_pln. Use conditional aggregates after a LEFT JOIN. Operators with no September missions need zeros in every measure; an unmatched row must not count as an unknown-status mission. Exclude guests from this operator report and order by operator id.


### 2.2. HW8.2 -- Possible duplicate operator identities

Find operator pairs sharing lowercased email after trimming ASCII spaces and sharing the same country. Exclude NULL or empty normalized emails; two NULL countries count as equal. Include soft-deleted operators. Return the smaller id, larger id, shared normalized_email, and country; show each pair once, including all pairs in larger duplicate groups, ordered by the two ids.


### 2.3. HW8.3 -- The previous completed mission in a stable history

For each registered operator's completed mission started before 2026-10-01, attach their immediately previous completed mission. Define history by started_at ascending then mission id ascending. Use LEFT JOIN LATERAL and retain first completed missions with NULL previous fields. Return mission_id, operator_id, previous_mission_id, and elapsed_hours rounded to two decimals; order by operator, start timestamp, and mission id.


### 2.4. HW8.4 -- Tags absent from September robot documentation

Find tags not attached to any technical document published in September 2026. A tag used only outside September qualifies, as does a completely unused tag. Use a LEFT JOIN anti join against qualifying document-tag relationships, avoiding accidental matches from out-of-range documents. Return tag id and name once, ordered by tag id.


### 2.5. HW8.5 -- Distinct operators deploying each manufacturer's robots

For each manufacturer, count distinct registered operators using its models in completed September missions and sum their historical deployment costs. Exclude guest missions from both measures; repeated models, robot counts, and repeat missions must not inflate operator counts. Return manufacturer id, name, registered_operators, and registered_deployment_cost_pln, retaining unused manufacturers with zeros and ordering by manufacturer id.


### 2.6. HW8.6 -- Operators two collaboration links away

For operator 1, find partners of direct partners, excluding operator 1 and all existing direct partners. operator_links is symmetric and stores both directions. Return candidate id, name, and mutual_partner_count, counting distinct intermediate operators rather than duplicate candidate rows. Order by mutual_partner_count descending then candidate id; use joins and an anti condition.


### 2.7. HW8.7 -- Inspections without prior completed deployment

Find inspections before 2026-10-01 where that operator has no completed mission involving the inspected model started at or before inspected_at. A start at the exact inspection timestamp qualifies; later starts do not. Return operator id/name, model id/name, score, and inspected_at, ordered by operator id then model id. Use an anti join without multiplying inspections by repeated deployments.


### 2.8. HW8.8 -- Two missions for planned-cost review per operator

Use LEFT JOIN LATERAL to return each operator's two highest-cost missions started before 2026-10-01 whose status is queued or SQL NULL. Rank by cost descending, started_at ascending, then mission id ascending; return at most two even when costs tie. Preserve operators without matches as a NULL-mission row. Show operator_id, mission_id, status, cost, and started_at, ordered by operator id then that ranking.


### 2.9. HW8.9 -- Robot model suggestions from direct partners

Suggest up to five robot models to operator 1 that direct partners used in completed September missions but operator 1 never used in a completed mission before 2026-10-01. Return model id, name, and distinct_partner_operators. Repeated deployments by one partner count once; rank by that count descending then model id, excluding guest missions and indirect partners.


### 2.10. HW8.10 -- Related technical documents using Jaccard similarity

For technical document 1, return up to five other documents sharing at least one tag. Show document id, name, shared_tags, union_tags, and similarity = shared_tags / union_tags rounded to three decimals. Rank by the unrounded ratio descending, shared_tags descending, then document id. Use bridge joins and grouped counts; identical tag sets have similarity 1 and repeated tags must not inflate scores.

