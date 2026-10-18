-- BEGIN IC6.1
SELECT c.id, c.name, c.country
FROM public.operators AS c
WHERE c.deleted_at IS NULL
  AND EXISTS (
      SELECT 1 FROM public.missions AS o
      WHERE o.operator_id = c.id AND o.status = 'completed'
        AND o.started_at >= TIMESTAMP '2026-09-01'
        AND o.started_at < TIMESTAMP '2026-10-01'
  )
ORDER BY c.id;
-- END IC6.1

-- BEGIN IC6.2
SELECT o.id, o.cost,
       (SELECT c.name FROM public.operators AS c WHERE c.id = o.operator_id)
           AS operator_name
FROM public.missions AS o
WHERE o.started_at < TIMESTAMP '2026-10-01'
  AND (o.status = 'queued' OR o.status IS NULL)
  AND o.cost >= 100
ORDER BY o.cost DESC, o.id
LIMIT 5;
-- END IC6.2

-- BEGIN IC6.3
-- NULL is unknown: email = NULL is never TRUE; use email IS NULL.
WITH contacts AS (
    SELECT c.id, c.email,
           CASE WHEN c.email IS NULL THEN 'null_email'
                WHEN btrim(c.email) = '' THEN 'blank_email'
                ELSE 'available' END AS contact_state
    FROM public.operators AS c
)
SELECT id, email, contact_state
FROM contacts
ORDER BY CASE contact_state WHEN 'null_email' THEN 1
                            WHEN 'blank_email' THEN 2 ELSE 3 END, id;
-- END IC6.3

-- BEGIN IC6.4
-- IS NOT DISTINCT FROM 'PL' matches PL, not NULL: one NULL operand differs
-- from a known value. Add an explicit IS NULL branch for unknown countries.
SELECT c.id, c.name, c.country
FROM public.operators AS c
WHERE c.country = 'PL' OR c.country IS NULL
ORDER BY c.country NULLS LAST, c.id;
-- END IC6.4

-- BEGIN IC6.5
-- Unescaped _ matches any single character; % matches any sequence.
SELECT b.id, b.name, b.unit_cost
FROM public.robot_models AS b
WHERE b.name LIKE '%!_%' ESCAPE '!'
   OR b.name LIKE '%!%%' ESCAPE '!'
ORDER BY b.id;
-- END IC6.5

-- BEGIN IC6.6
SELECT o.id, o.status, o.started_at, o.cost
FROM public.missions AS o
WHERE o.started_at < TIMESTAMP '2026-10-01'
ORDER BY CASE WHEN o.status = 'queued' THEN 1
              WHEN o.status IS NULL THEN 2
              WHEN o.status = 'completed' THEN 3 ELSE 4 END,
         o.started_at, o.cost DESC, o.id;
-- END IC6.6

-- BEGIN IC6.7
SELECT o.id, o.started_at,
       floor(extract(epoch FROM
           (TIMESTAMP '2026-10-01' - o.started_at)) / 86400)::integer AS age_days
FROM public.missions AS o
WHERE o.status = 'completed'
  AND o.started_at < TIMESTAMP '2026-10-01' - INTERVAL '60 days'
ORDER BY o.started_at, o.id;
-- END IC6.7

-- BEGIN IC6.8
WITH activation AS (
    SELECT c.id, c.name, c.registered_at,
           (SELECT min(o.started_at) FROM public.missions AS o
            WHERE o.operator_id = c.id AND o.status = 'completed'
              AND o.started_at < TIMESTAMP '2026-10-01') AS first_completed_at
    FROM public.operators AS c
    WHERE c.registered_at >= TIMESTAMP '2026-01-01'
      AND c.registered_at < TIMESTAMP '2026-10-01'
)
SELECT id, name, registered_at, first_completed_at,
       first_completed_at::date - registered_at::date AS calendar_days_to_first
FROM activation
ORDER BY id;
-- END IC6.8

-- BEGIN IC6.9
SELECT c.id, c.name
FROM public.operators AS c
WHERE EXISTS (
    SELECT 1 FROM public.missions AS o
    WHERE o.operator_id = c.id AND o.started_at < TIMESTAMP '2026-10-01'
)
AND NOT EXISTS (
    SELECT 1 FROM public.missions AS o
    WHERE o.operator_id = c.id AND o.status = 'aborted'
      AND o.started_at < TIMESTAMP '2026-10-01'
)
ORDER BY c.id;
-- END IC6.9

-- BEGIN IC6.10
WITH candidates AS (
    SELECT o.id, o.operator_id, o.cost,
           (SELECT count(*) FROM public.missions AS p
            WHERE p.operator_id = o.operator_id AND p.status = 'completed'
              AND p.started_at < TIMESTAMP '2026-09-01') AS baseline_count,
           (SELECT avg(p.cost) FROM public.missions AS p
            WHERE p.operator_id = o.operator_id AND p.status = 'completed'
              AND p.started_at < TIMESTAMP '2026-09-01') AS baseline_mean
    FROM public.missions AS o
    WHERE o.operator_id IS NOT NULL AND o.status = 'completed'
      AND o.started_at >= TIMESTAMP '2026-09-01'
      AND o.started_at < TIMESTAMP '2026-10-01'
)
SELECT id, operator_id, cost, round(baseline_mean, 2) AS baseline_mean
FROM candidates
WHERE baseline_count >= 2 AND cost > baseline_mean
ORDER BY id;
-- END IC6.10

-- BEGIN HW6.1
WITH normalized AS (
    SELECT c.id, c.email, NULLIF(lower(btrim(c.email)), '') AS clean_email
    FROM public.operators AS c
), diagnostics AS (
    SELECT id, email,
           array_remove(ARRAY[
               CASE WHEN email IS NULL THEN 'null_email' END,
               CASE WHEN email IS NOT NULL AND clean_email IS NULL
                    THEN 'blank_email' END,
               CASE WHEN email LIKE '% %' THEN 'contains_space' END,
               CASE WHEN clean_email IS NOT NULL AND strpos(clean_email, '@') = 0
                    THEN 'missing_at' END,
               CASE WHEN length(clean_email) - length(replace(clean_email, '@', '')) >= 2
                    THEN 'multiple_at' END,
               CASE WHEN left(clean_email, 1) = '.' OR right(clean_email, 1) = '.'
                    THEN 'edge_dot' END,
               CASE WHEN clean_email LIKE '%..%' THEN 'consecutive_dots' END
           ], NULL) AS reasons
    FROM normalized
)
SELECT id, email, reasons
FROM diagnostics
WHERE cardinality(reasons) > 0
ORDER BY id;
-- END HW6.1

-- BEGIN HW6.2
WITH completed AS (
    SELECT o.id, o.cost,
           (SELECT c.country FROM public.operators AS c WHERE c.id = o.operator_id)
               AS country
    FROM public.missions AS o
    WHERE o.status = 'completed' AND o.started_at < TIMESTAMP '2026-10-01'
)
SELECT p.country, p.id AS mission_id, p.cost
FROM completed AS p
WHERE (SELECT count(DISTINCT higher.cost)
       FROM completed AS higher
       WHERE higher.country IS NOT DISTINCT FROM p.country
         AND higher.cost > p.cost) = 1
ORDER BY p.country NULLS LAST, p.id;
-- END HW6.2

-- BEGIN HW6.3
WITH activity AS (
    SELECT c.id, c.registered_at, c.deleted_at,
           (SELECT max(o.started_at) FROM public.missions AS o
            WHERE o.operator_id = c.id AND o.status = 'completed'
              AND o.started_at < TIMESTAMP '2026-10-01') AS last_completed_at
    FROM public.operators AS c
    WHERE c.registered_at < TIMESTAMP '2026-10-01'
)
SELECT id, last_completed_at,
       CASE WHEN deleted_at < TIMESTAMP '2026-10-01' THEN 'deactivated'
            WHEN registered_at >= TIMESTAMP '2026-09-01' THEN 'new'
            WHEN last_completed_at < TIMESTAMP '2026-10-01' - INTERVAL '180 days'
                 THEN 'dormant'
            -- The broader experienced condition must come after dormant.
            WHEN last_completed_at IS NOT NULL THEN 'experienced'
            ELSE 'unproven' END AS segment
FROM activity
ORDER BY id;
-- END HW6.3

-- BEGIN HW6.4
WITH contacts AS (
    SELECT c.id, c.name, c.country, lower(btrim(c.email)) AS clean_email
    FROM public.operators AS c
    WHERE char_length(c.name) >= 2
)
SELECT id,
       left(name, 1) || repeat('*', char_length(name) - 2) || right(name, 1)
           AS masked_name,
       CASE WHEN length(clean_email) - length(replace(clean_email, '@', '')) = 1
                  AND strpos(clean_email, '@') > 1
                  AND strpos(clean_email, '@') < length(clean_email)
                  AND clean_email NOT LIKE '% %'
            THEN left(clean_email, 1) || '***@' || split_part(clean_email, '@', 2)
            ELSE NULL END AS masked_email,
       country
FROM contacts
ORDER BY id;
-- END HW6.4

-- BEGIN HW6.5
WITH completed_missions AS (
    SELECT o.id, o.operator_id, o.cost,
           (SELECT sum(p.cost) FROM public.missions AS p
            WHERE p.operator_id = o.operator_id AND p.status = 'completed'
              AND p.started_at < TIMESTAMP '2026-10-01') AS total_completed_cost
    FROM public.missions AS o
    WHERE o.operator_id IS NOT NULL AND o.status = 'completed'
      AND o.started_at >= TIMESTAMP '2026-09-01'
      AND o.started_at < TIMESTAMP '2026-10-01'
)
SELECT id AS mission_id, operator_id, cost,
       round(100.0 * cost / NULLIF(total_completed_cost, 0), 2) AS completed_cost_share_pct
FROM completed_missions
ORDER BY operator_id, id;
-- END HW6.5

-- BEGIN HW6.6
SELECT b.id, b.name, b.unit_cost
FROM public.robot_models AS b
WHERE NOT EXISTS (
    SELECT 1 FROM public.mission_robots AS oi
    WHERE oi.robot_model_id = b.id
      AND EXISTS (
          SELECT 1 FROM public.missions AS o
          WHERE o.id = oi.mission_id AND o.status = 'completed'
            AND o.started_at < TIMESTAMP '2026-10-01'
      )
)
ORDER BY b.id;
-- END HW6.6

-- BEGIN HW6.7
WITH counts AS (
    SELECT c.id,
           (SELECT count(*) FROM public.missions AS o
            WHERE o.operator_id = c.id
              AND o.started_at >= TIMESTAMP '2026-09-01'
              AND o.started_at < TIMESTAMP '2026-10-01') AS total_missions,
           (SELECT count(*) FROM public.missions AS o
            WHERE o.operator_id = c.id AND o.status = 'aborted'
              AND o.started_at >= TIMESTAMP '2026-09-01'
              AND o.started_at < TIMESTAMP '2026-10-01') AS aborted_missions
    FROM public.operators AS c
)
SELECT id, total_missions, aborted_missions,
       round(100.0 * aborted_missions / NULLIF(total_missions, 0), 2) AS abort_pct
FROM counts
WHERE total_missions >= 3
  AND 1.0 * aborted_missions / NULLIF(total_missions, 0) >= 0.25
ORDER BY 1.0 * aborted_missions / NULLIF(total_missions, 0) DESC, id;
-- END HW6.7

-- BEGIN HW6.8
WITH ranges AS (
    SELECT c.id,
           (SELECT count(*) FROM public.missions AS o
            WHERE o.operator_id = c.id AND o.status = 'completed'
              AND o.started_at < TIMESTAMP '2026-10-01') AS completed_mission_count,
           (SELECT min(o.cost) FROM public.missions AS o
            WHERE o.operator_id = c.id AND o.status = 'completed'
              AND o.started_at < TIMESTAMP '2026-10-01') AS minimum_completed_cost,
           (SELECT max(o.cost) FROM public.missions AS o
            WHERE o.operator_id = c.id AND o.status = 'completed'
              AND o.started_at < TIMESTAMP '2026-10-01') AS maximum_completed_cost
    FROM public.operators AS c
)
SELECT id, completed_mission_count, minimum_completed_cost, maximum_completed_cost,
       maximum_completed_cost - minimum_completed_cost AS cost_range
FROM ranges
ORDER BY cost_range DESC NULLS LAST, id;
-- END HW6.8

-- BEGIN HW6.9
WITH calendar AS (
    SELECT generate_series(TIMESTAMP '2026-09-01', TIMESTAMP '2026-09-30',
                           INTERVAL '1 day') AS day_start
)
SELECT d.day_start::date AS activity_day
FROM calendar AS d
WHERE NOT EXISTS (
    SELECT 1 FROM public.missions AS o
    WHERE o.status = 'completed'
      AND o.started_at >= d.day_start
      AND o.started_at < d.day_start + INTERVAL '1 day'
)
ORDER BY activity_day;
-- END HW6.9

-- BEGIN HW6.10
WITH calendar AS (
    SELECT generate_series(TIMESTAMP '2026-09-24', TIMESTAMP '2026-09-30',
                           INTERVAL '1 day') AS day_start
)
SELECT d.day_start::date AS activity_day,
       (SELECT count(*) FROM public.operators AS c
        WHERE c.registered_at >= d.day_start
          AND c.registered_at < d.day_start + INTERVAL '1 day') AS new_operators,
       (SELECT count(*) FROM public.operators AS c
        WHERE (SELECT min(o.started_at) FROM public.missions AS o
               WHERE o.operator_id = c.id AND o.status = 'completed'
                 AND o.started_at < TIMESTAMP '2026-10-01') >= d.day_start
          AND (SELECT min(o.started_at) FROM public.missions AS o
               WHERE o.operator_id = c.id AND o.status = 'completed'
                 AND o.started_at < TIMESTAMP '2026-10-01')
                  < d.day_start + INTERVAL '1 day') AS first_completion_operators,
       (SELECT coalesce(sum(o.cost), 0) FROM public.missions AS o
        WHERE o.status = 'completed' AND o.started_at >= d.day_start
          AND o.started_at < d.day_start + INTERVAL '1 day') AS completed_cost_pln
FROM calendar AS d
ORDER BY activity_day;
-- END HW6.10
