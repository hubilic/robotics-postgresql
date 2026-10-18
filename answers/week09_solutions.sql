-- BEGIN IC9.1
-- Grouping the mission's operator_id does not establish a PostgreSQL functional
-- dependency for the joined operator's name. Include the displayed name in
-- GROUP BY; grouping by name alone would merge operators sharing a name.
SELECT o.operator_id, c.name, COUNT(*) AS mission_count,
       COALESCE(SUM(o.cost) FILTER (WHERE o.status = 'completed'), 0) AS completed_cost
FROM public.missions AS o
LEFT JOIN public.operators AS c ON c.id = o.operator_id
WHERE o.started_at >= TIMESTAMP '2026-09-01'
  AND o.started_at < TIMESTAMP '2026-10-01'
GROUP BY o.operator_id, c.name
ORDER BY o.operator_id NULLS LAST;
-- END IC9.1

-- BEGIN IC9.2
-- COUNT(operator_id) counts registered-operator missions, not unique people.
-- Subtracting guest missions from all missions still counts repeat missions.
SELECT COUNT(*) AS mission_rows, COUNT(operator_id) AS registered_mission_rows,
       COUNT(DISTINCT operator_id) AS distinct_registered_operators,
       COUNT(*) FILTER (WHERE operator_id IS NULL) AS guest_mission_rows,
       COUNT(status) AS known_status_rows,
       COUNT(DISTINCT operator_id) FILTER (WHERE status = 'completed') AS distinct_active_operators
FROM public.missions
WHERE started_at >= TIMESTAMP '2026-09-01'
  AND started_at < TIMESTAMP '2026-10-01';
-- END IC9.2

-- BEGIN IC9.3
SELECT started_at::date AS mission_day, COUNT(*) AS completed_missions,
       SUM(cost) AS completed_cost, ROUND(AVG(cost), 2) AS average_completed_mission
FROM public.missions
WHERE started_at >= TIMESTAMP '2026-09-01'
  AND started_at < TIMESTAMP '2026-10-01'
  AND status = 'completed'
GROUP BY started_at::date
HAVING COUNT(*) >= 3 AND SUM(cost) >= 500
ORDER BY mission_day;
-- END IC9.3

-- BEGIN IC9.4
SELECT c.country::text AS country, o.status,
       GROUPING(c.country) AS country_subtotal,
       GROUPING(o.status) AS status_subtotal,
       COUNT(*) AS mission_count,
       COALESCE(SUM(o.cost) FILTER (WHERE o.status = 'completed'), 0) AS completed_cost
FROM public.missions AS o
LEFT JOIN public.operators AS c ON c.id = o.operator_id
WHERE o.started_at >= TIMESTAMP '2026-09-01'
  AND o.started_at < TIMESTAMP '2026-10-01'
GROUP BY ROLLUP(c.country, o.status)
ORDER BY country_subtotal, country NULLS FIRST,
         status_subtotal, o.status NULLS FIRST;
-- END IC9.4

-- BEGIN IC9.5
SELECT c.id AS operator_id, c.name, COUNT(o.id) AS total_missions,
       COUNT(o.id) FILTER (WHERE o.status = 'completed') AS completed_missions,
       COUNT(o.id) FILTER (WHERE o.status = 'queued') AS queued_missions,
       COUNT(o.id) FILTER (WHERE o.status = 'aborted') AS aborted_missions,
       COUNT(o.id) FILTER (WHERE o.status IS NULL) AS unknown_status_missions,
       COALESCE(SUM(o.cost) FILTER (WHERE o.status = 'completed'), 0) AS completed_cost
FROM public.operators AS c
LEFT JOIN public.missions AS o
  ON o.operator_id = c.id
 AND o.started_at >= TIMESTAMP '2026-09-01'
 AND o.started_at < TIMESTAMP '2026-10-01'
GROUP BY c.id, c.name
ORDER BY c.id;
-- END IC9.5

-- BEGIN IC9.6
WITH totals AS (
    SELECT c.id AS operator_id, c.name, c.country,
           COALESCE(SUM(o.cost) FILTER (WHERE o.status = 'completed'), 0) AS completed_cost
    FROM public.operators AS c
    LEFT JOIN public.missions AS o
      ON o.operator_id = c.id
     AND o.started_at >= TIMESTAMP '2026-09-01'
     AND o.started_at < TIMESTAMP '2026-10-01'
    GROUP BY c.id, c.name, c.country
)
SELECT t.operator_id, t.name, t.country::text AS country, t.completed_cost
FROM totals AS t
WHERE NOT EXISTS (
    SELECT 1 FROM totals AS better
    WHERE better.country IS NOT DISTINCT FROM t.country
      AND better.completed_cost > t.completed_cost
)
ORDER BY country NULLS FIRST, operator_id;
-- END IC9.6

-- BEGIN IC9.7
WITH frequencies AS (
    SELECT operator_id, cost, COUNT(*) AS frequency
    FROM public.missions
    WHERE operator_id IS NOT NULL AND status = 'completed'
      AND started_at >= TIMESTAMP '2026-09-01'
      AND started_at < TIMESTAMP '2026-10-01'
    GROUP BY operator_id, cost
), intervals AS (
    SELECT a.operator_id, a.cost, a.frequency,
           COALESCE(SUM(b.frequency) FILTER (WHERE b.cost < a.cost), 0) AS smaller_rows,
           SUM(b.frequency) AS total_rows
    FROM frequencies AS a
    JOIN frequencies AS b ON b.operator_id = a.operator_id
    GROUP BY a.operator_id, a.cost, a.frequency
), medians AS (
    SELECT operator_id, MAX(total_rows)::bigint AS completed_missions,
           ROUND(AVG(cost), 2) AS median_cost
    FROM intervals
    WHERE smaller_rows < FLOOR((total_rows + 2) / 2)
      AND smaller_rows + frequency >= FLOOR((total_rows + 1) / 2)
    GROUP BY operator_id
)
SELECT c.id AS operator_id, c.name, COALESCE(m.completed_missions, 0) AS completed_missions,
       m.median_cost
FROM public.operators AS c
LEFT JOIN medians AS m ON m.operator_id = c.id
ORDER BY c.id;
-- END IC9.7

-- BEGIN IC9.8
WITH calendar AS (
    SELECT day::date AS mission_day
    FROM generate_series(TIMESTAMP '2026-09-01', TIMESTAMP '2026-09-30', INTERVAL '1 day') AS g(day)
), daily AS (
    SELECT c.mission_day,
           COALESCE(SUM(o.cost) FILTER (WHERE o.status = 'completed'), 0) AS completed_cost
    FROM calendar AS c
    LEFT JOIN public.missions AS o
      ON o.started_at >= c.mission_day::timestamp
     AND o.started_at < c.mission_day::timestamp + INTERVAL '1 day'
    GROUP BY c.mission_day
)
SELECT d.mission_day, d.completed_cost,
       (SELECT SUM(previous.completed_cost) FROM daily AS previous
        WHERE previous.mission_day <= d.mission_day) AS month_to_date_cost
FROM daily AS d
ORDER BY d.mission_day;
-- END IC9.8

-- BEGIN IC9.9
WITH completed_missions AS (
    SELECT date_trunc('month', o.started_at)::date AS mission_month,
           c.country, o.cost
    FROM public.missions AS o
    LEFT JOIN public.operators AS c ON c.id = o.operator_id
    WHERE o.status = 'completed'
      AND o.started_at >= TIMESTAMP '2026-04-01'
      AND o.started_at < TIMESTAMP '2026-10-01'
)
SELECT mission_month, country::text AS country,
       GROUPING(mission_month) AS month_subtotal,
       GROUPING(country) AS country_subtotal,
       COUNT(*) AS completed_missions, SUM(cost) AS completed_cost
FROM completed_missions
GROUP BY GROUPING SETS ((mission_month, country), (mission_month), ())
ORDER BY month_subtotal, mission_month, country_subtotal, country NULLS FIRST;
-- END IC9.9

-- BEGIN IC9.10
WITH calendar AS (
    SELECT day::date AS mission_day
    FROM generate_series(TIMESTAMP '2026-09-24', TIMESTAMP '2026-09-30', INTERVAL '1 day') AS g(day)
), first_completed AS (
    SELECT operator_id, MIN(started_at)::date AS first_completed_day
    FROM public.missions
    WHERE status = 'completed' AND operator_id IS NOT NULL
      AND started_at < TIMESTAMP '2026-10-01'
    GROUP BY operator_id
), country_daily AS (
    SELECT o.started_at::date AS mission_day, c.country,
           SUM(o.cost) AS completed_cost
    FROM public.missions AS o
    LEFT JOIN public.operators AS c ON c.id = o.operator_id
    WHERE o.status = 'completed'
      AND o.started_at >= TIMESTAMP '2026-09-24'
      AND o.started_at < TIMESTAMP '2026-10-01'
    GROUP BY o.started_at::date, c.country
), daily AS (
    SELECT cal.mission_day, COUNT(o.id) AS completed_missions,
           COALESCE(SUM(o.cost), 0) AS completed_cost,
           COUNT(DISTINCT o.operator_id) AS active_operators,
           COUNT(DISTINCT o.operator_id) FILTER (WHERE f.first_completed_day = cal.mission_day) AS new_active_operators,
           COUNT(DISTINCT o.operator_id) FILTER (WHERE f.first_completed_day < cal.mission_day) AS returning_active_operators
    FROM calendar AS cal
    LEFT JOIN public.missions AS o
      ON o.started_at >= cal.mission_day::timestamp
     AND o.started_at < cal.mission_day::timestamp + INTERVAL '1 day'
     AND o.status = 'completed'
    LEFT JOIN first_completed AS f ON f.operator_id = o.operator_id
    GROUP BY cal.mission_day
)
SELECT d.mission_day, d.completed_missions, d.completed_cost, d.active_operators,
       d.new_active_operators, d.returning_active_operators,
       (SELECT cd.country::text FROM country_daily AS cd
        WHERE cd.mission_day = d.mission_day
        ORDER BY cd.completed_cost DESC, cd.country NULLS LAST LIMIT 1) AS top_country
FROM daily AS d
ORDER BY d.mission_day;
-- END IC9.10

-- BEGIN HW9.1
-- COUNT(value) ignores NULL; COUNT(*) counts every row. AVG(value) divides
-- by non-NULL values, while AVG(COALESCE(value,0)) divides by every row.
SELECT COUNT(*) AS row_count, COUNT(value) AS nonnull_count,
       SUM(value) AS total_value, ROUND(AVG(value), 2) AS nonnull_average,
       MIN(value) AS minimum_value, MAX(value) AS maximum_value,
       ROUND(AVG(COALESCE(value, 0)), 2) AS null_as_zero_average
FROM public.sensor_readings;
-- END HW9.1

-- BEGIN HW9.2
WITH status_totals AS (
    SELECT c.country, o.status, COUNT(*) AS mission_count
    FROM public.missions AS o
    LEFT JOIN public.operators AS c ON c.id = o.operator_id
    WHERE o.started_at >= TIMESTAMP '2026-09-01'
      AND o.started_at < TIMESTAMP '2026-10-01'
    GROUP BY c.country, o.status
)
SELECT s.country::text AS country, s.status, s.mission_count,
       ROUND(100.0 * s.mission_count /
             NULLIF((SELECT SUM(t.mission_count) FROM status_totals AS t
                     WHERE t.country IS NOT DISTINCT FROM s.country), 0), 2) AS country_mission_pct
FROM status_totals AS s
ORDER BY country NULLS FIRST, s.status NULLS FIRST;
-- END HW9.2

-- BEGIN HW9.3
WITH counts AS (
    SELECT operator_id, COUNT(*) AS total_missions
    FROM public.missions
    WHERE operator_id IS NOT NULL AND started_at < TIMESTAMP '2026-10-01'
    GROUP BY operator_id
)
SELECT c.id AS operator_id, c.name, COALESCE(n.total_missions, 0) AS total_missions,
       first_mission.id AS first_mission_id, first_mission.started_at AS first_mission_at,
       first_mission.cost AS first_cost,
       last_mission.id AS last_mission_id, last_mission.started_at AS last_mission_at,
       last_mission.cost AS last_cost
FROM public.operators AS c
LEFT JOIN counts AS n ON n.operator_id = c.id
LEFT JOIN LATERAL (
    SELECT o.id, o.started_at, o.cost
    FROM public.missions AS o
    WHERE o.operator_id = c.id AND o.started_at < TIMESTAMP '2026-10-01'
    ORDER BY o.started_at, o.id LIMIT 1
) AS first_mission ON true
LEFT JOIN LATERAL (
    SELECT o.id, o.started_at, o.cost
    FROM public.missions AS o
    WHERE o.operator_id = c.id AND o.started_at < TIMESTAMP '2026-10-01'
    ORDER BY o.started_at DESC, o.id DESC LIMIT 1
) AS last_mission ON true
ORDER BY c.id;
-- END HW9.3

-- BEGIN HW9.4
SELECT b.id AS robot_model_id, b.name, COUNT(o.id) AS mission_count,
       COUNT(DISTINCT o.operator_id) AS distinct_registered_operators,
       COUNT(DISTINCT o.operator_id) FILTER (WHERE o.status = 'completed') AS distinct_active_operators,
       COALESCE(SUM(oi.robot_count) FILTER (WHERE o.status = 'completed'), 0) AS completed_units,
       COALESCE(SUM(oi.robot_count * oi.unit_cost) FILTER (WHERE o.status = 'completed'), 0) AS completed_line_cost
FROM public.robot_models AS b
LEFT JOIN public.mission_robots AS oi ON oi.robot_model_id = b.id
LEFT JOIN public.missions AS o
  ON o.id = oi.mission_id
 AND o.started_at >= TIMESTAMP '2026-09-01'
 AND o.started_at < TIMESTAMP '2026-10-01'
GROUP BY b.id, b.name
ORDER BY b.id;
-- END HW9.4

-- BEGIN HW9.5
WITH buckets(bucket_no, cost_bucket) AS (
    VALUES (1, '[0,100)'), (2, '[100,250)'), (3, '[250,500)'),
           (4, '[500,1000)'), (5, '[1000,+infinity)')
), classified AS (
    SELECT id, cost, status,
           CASE WHEN cost < 100 THEN 1 WHEN cost < 250 THEN 2
                WHEN cost < 500 THEN 3 WHEN cost < 1000 THEN 4 ELSE 5 END AS bucket_no
    FROM public.missions
    WHERE started_at >= TIMESTAMP '2026-09-01'
      AND started_at < TIMESTAMP '2026-10-01'
)
SELECT b.bucket_no, b.cost_bucket, COUNT(c.id) AS mission_count,
       COUNT(c.id) FILTER (WHERE c.status = 'completed') AS completed_missions,
       COALESCE(SUM(c.cost) FILTER (WHERE c.status = 'completed'), 0) AS completed_cost
FROM buckets AS b
LEFT JOIN classified AS c USING (bucket_no)
GROUP BY b.bucket_no, b.cost_bucket
ORDER BY b.bucket_no;
-- END HW9.5

-- BEGIN HW9.6
WITH operator_stats AS (
    SELECT operator_id, COUNT(*) AS completed_missions,
           AVG(cost) AS mean_cost, STDDEV_POP(cost) AS population_sd
    FROM public.missions
    WHERE operator_id IS NOT NULL AND status = 'completed'
      AND started_at < TIMESTAMP '2026-10-01'
    GROUP BY operator_id
    HAVING COUNT(*) >= 5
)
SELECT o.operator_id, o.id AS mission_id, o.cost,
       ROUND(s.mean_cost, 2) AS mean_cost,
       ROUND(s.population_sd, 2) AS population_sd,
       ROUND((o.cost - s.mean_cost) / NULLIF(s.population_sd, 0), 3) AS z_score
FROM public.missions AS o
JOIN operator_stats AS s ON s.operator_id = o.operator_id
WHERE o.status = 'completed' AND o.started_at < TIMESTAMP '2026-10-01'
  AND o.cost > s.mean_cost + 2 * s.population_sd
ORDER BY o.operator_id, o.cost DESC, o.id;
-- END HW9.6

-- BEGIN HW9.7
WITH calendar AS (
    SELECT day::date AS metric_day
    FROM generate_series(TIMESTAMP '2026-09-24', TIMESTAMP '2026-09-30', INTERVAL '1 day') AS g(day)
), pivoted AS (
    SELECT c.metric_day,
           MAX(m.value) FILTER (WHERE m.metric = 'sensor_reads') AS sensor_reads,
           MAX(m.value) FILTER (WHERE m.metric = 'faults') AS faults,
           MAX(m.value) FILTER (WHERE m.metric = 'missions') AS missions
    FROM calendar AS c
    LEFT JOIN public.robot_metrics AS m ON m.day = c.metric_day
    GROUP BY c.metric_day
)
SELECT metric_day, sensor_reads, faults, missions,
       ROUND(100.0 * missions / NULLIF(sensor_reads, 0), 2) AS missions_per_sensor_read_pct
FROM pivoted
ORDER BY metric_day;
-- END HW9.7

-- BEGIN HW9.8
WITH deployments AS (
    SELECT o.operator_id, oi.robot_model_id, SUM(oi.robot_count) AS completed_units,
           SUM(oi.robot_count * oi.unit_cost) AS completed_line_cost
    FROM public.missions AS o
    JOIN public.mission_robots AS oi ON oi.mission_id = o.id
    WHERE o.operator_id IS NOT NULL AND o.status = 'completed'
      AND o.started_at >= TIMESTAMP '2026-09-01'
      AND o.started_at < TIMESTAMP '2026-10-01'
    GROUP BY o.operator_id, oi.robot_model_id
)
SELECT p.operator_id, c.name AS operator_name, p.robot_model_id, b.name AS robot_model_name, p.completed_units, p.completed_line_cost
FROM deployments AS p
JOIN public.operators AS c ON c.id = p.operator_id
JOIN public.robot_models AS b ON b.id = p.robot_model_id
WHERE (SELECT COUNT(*) FROM deployments AS better
       WHERE better.operator_id = p.operator_id
         AND (better.completed_units > p.completed_units
           OR (better.completed_units = p.completed_units AND better.completed_line_cost > p.completed_line_cost)
           OR (better.completed_units = p.completed_units AND better.completed_line_cost = p.completed_line_cost
               AND better.robot_model_id < p.robot_model_id))) < 3
ORDER BY p.operator_id, p.completed_units DESC, p.completed_line_cost DESC, p.robot_model_id;
-- END HW9.8

-- BEGIN HW9.9
WITH hours AS (
    SELECT generate_series(TIMESTAMP '2026-09-30 00:00:00',
                           TIMESTAMP '2026-09-30 23:00:00', INTERVAL '1 hour') AS hour_start
)
SELECT h.hour_start, COUNT(o.id) AS total_missions,
       COUNT(o.id) FILTER (WHERE o.status = 'completed') AS completed_missions,
       COUNT(o.id) FILTER (WHERE o.operator_id IS NULL) AS guest_missions,
       COALESCE(SUM(o.cost) FILTER (WHERE o.status = 'completed'), 0) AS completed_cost
FROM hours AS h
LEFT JOIN public.missions AS o
  ON o.started_at >= h.hour_start AND o.started_at < h.hour_start + INTERVAL '1 hour'
GROUP BY h.hour_start
ORDER BY h.hour_start;
-- END HW9.9

-- BEGIN HW9.10
WITH cohort_operators AS (
    SELECT id AS operator_id, registered_at,
           date_trunc('month', registered_at)::date AS cohort_month
    FROM public.operators
    WHERE registered_at < TIMESTAMP '2026-10-01'
), cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM cohort_operators GROUP BY cohort_month
), grid AS (
    SELECT cs.cohort_month, offsets.month_offset, cs.cohort_size,
           (cs.cohort_month + offsets.month_offset * INTERVAL '1 month')::date AS activity_month
    FROM cohort_sizes AS cs
    CROSS JOIN generate_series(0, 5) AS offsets(month_offset)
    WHERE cs.cohort_month + offsets.month_offset * INTERVAL '1 month' < TIMESTAMP '2026-10-01'
), activity AS (
    SELECT DISTINCT c.cohort_month, c.operator_id,
           date_trunc('month', o.started_at)::date AS activity_month
    FROM cohort_operators AS c
    JOIN public.missions AS o ON o.operator_id = c.operator_id
    WHERE o.status = 'completed' AND o.started_at >= c.registered_at
      AND o.started_at < TIMESTAMP '2026-10-01'
)
SELECT g.cohort_month, g.month_offset, g.activity_month, g.cohort_size,
       COUNT(a.operator_id) AS active_operators,
       ROUND(100.0 * COUNT(a.operator_id) / NULLIF(g.cohort_size, 0), 2) AS retention_pct
FROM grid AS g
LEFT JOIN activity AS a
  ON a.cohort_month = g.cohort_month AND a.activity_month = g.activity_month
GROUP BY g.cohort_month, g.month_offset, g.activity_month, g.cohort_size
ORDER BY g.cohort_month, g.month_offset;
-- END HW9.10
