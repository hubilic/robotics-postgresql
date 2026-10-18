-- BEGIN IC8.1
-- An INNER JOIN removes guest missions because operator_id NULL matches no key.
SELECT o.id AS mission_id, c.name AS operator_name, c.country, o.cost
FROM public.missions AS o
LEFT JOIN public.operators AS c ON c.id = o.operator_id
WHERE o.started_at >= TIMESTAMP '2026-09-01'
  AND o.started_at < TIMESTAMP '2026-10-01'
  AND (o.status = 'queued' OR o.status IS NULL)
ORDER BY o.id;
-- END IC8.1

-- BEGIN IC8.2
SELECT o.id AS mission_id, b.name AS robot_model_name, a.name AS manufacturer_name,
       oi.robot_count, oi.unit_cost AS historical_unit_cost,
       b.unit_cost AS current_unit_cost,
       oi.robot_count * oi.unit_cost AS historical_deployment_cost
FROM public.missions AS o
JOIN public.mission_robots AS oi ON oi.mission_id = o.id
JOIN public.robot_models AS b ON b.id = oi.robot_model_id
JOIN public.manufacturers AS a ON a.id = b.manufacturer_id
WHERE o.started_at >= TIMESTAMP '2026-09-01'
  AND o.started_at < TIMESTAMP '2026-10-01'
  AND oi.unit_cost <> b.unit_cost
ORDER BY o.id, b.id;
-- END IC8.2

-- BEGIN IC8.3
SELECT c.id, c.name
FROM public.operators AS c
LEFT JOIN public.missions AS o
  ON o.operator_id = c.id AND o.status = 'completed'
 AND o.started_at >= TIMESTAMP '2026-09-01'
 AND o.started_at < TIMESTAMP '2026-10-01'
WHERE o.id IS NULL
ORDER BY c.id;
-- END IC8.3

-- BEGIN IC8.4
SELECT c.id, c.name AS category_name, parent.name AS parent_name,
       grandparent.name AS grandparent_name
FROM public.robot_categories AS c
LEFT JOIN public.robot_categories AS parent ON parent.id = c.parent_id
LEFT JOIN public.robot_categories AS grandparent ON grandparent.id = parent.parent_id
ORDER BY c.id;
-- END IC8.4

-- BEGIN IC8.5
SELECT c.id AS operator_id, c.name, o.id AS mission_id, o.started_at
FROM public.operators AS c
LEFT JOIN public.missions AS o
  ON o.operator_id = c.id
 AND o.started_at >= c.registered_at
 AND o.started_at < c.registered_at + INTERVAL '14 days'
 AND o.started_at < TIMESTAMP '2026-10-01'
WHERE c.registered_at < TIMESTAMP '2026-10-01'
ORDER BY c.id, o.started_at NULLS LAST, o.id NULLS LAST;
-- END IC8.5

-- BEGIN IC8.6
SELECT coalesce(m.robot_model_id, e.robot_model_id) AS robot_model_id,
       m.available_units AS morning_units, e.available_units AS evening_units,
       CASE WHEN m.robot_model_id IS NULL THEN 'added'
            WHEN e.robot_model_id IS NULL THEN 'removed'
            ELSE 'changed' END AS change_type
FROM public.robot_inventory_morning AS m
FULL OUTER JOIN public.robot_inventory_evening AS e ON e.robot_model_id = m.robot_model_id
WHERE m.robot_model_id IS NULL OR e.robot_model_id IS NULL
   OR m.available_units IS DISTINCT FROM e.available_units
ORDER BY robot_model_id;
-- END IC8.6

-- BEGIN IC8.7
WITH calendar AS (
    SELECT generate_series(TIMESTAMP '2026-09-24', TIMESTAMP '2026-09-30',
                           INTERVAL '1 day') AS day_start
)
SELECT c.id AS operator_id, d.day_start::date AS activity_day,
       count(o.id) AS completed_mission_count,
       coalesce(sum(o.cost), 0) AS completed_cost_pln
FROM public.operators AS c
CROSS JOIN calendar AS d
LEFT JOIN public.missions AS o
  ON o.operator_id = c.id AND o.status = 'completed'
 AND o.started_at >= d.day_start
 AND o.started_at < d.day_start + INTERVAL '1 day'
WHERE d.day_start::date >= c.registered_at::date
GROUP BY c.id, d.day_start
ORDER BY c.id, d.day_start;
-- END IC8.7

-- BEGIN IC8.8
SELECT c.id AS operator_id, c.name, chosen.id AS mission_id,
       chosen.started_at, chosen.cost
FROM public.operators AS c
LEFT JOIN LATERAL (
    SELECT o.id, o.started_at, o.cost
    FROM public.missions AS o
    WHERE o.operator_id = c.id AND o.status = 'completed'
      AND o.started_at < TIMESTAMP '2026-10-01'
    ORDER BY o.started_at DESC, o.id DESC
    LIMIT 1
) AS chosen ON true
ORDER BY c.id;
-- END IC8.8

-- BEGIN IC8.9
SELECT a.id, a.name, count(t.id) AS tag_count,
       coalesce(string_agg(t.name, ', ' ORDER BY t.name), '') AS tag_names
FROM public.technical_documents AS a
LEFT JOIN public.document_tags AS at ON at.document_id = a.id
LEFT JOIN public.tags AS t ON t.id = at.tag_id
GROUP BY a.id, a.name
ORDER BY a.id;
-- END IC8.9

-- BEGIN IC8.10
WITH completed_models AS (
    SELECT oi.robot_model_id, sum(oi.robot_count) AS robots_deployed,
           sum(oi.robot_count * oi.unit_cost) AS completed_cost_pln
    FROM public.mission_robots AS oi
    JOIN public.missions AS o ON o.id = oi.mission_id
    WHERE o.status = 'completed'
      AND o.started_at >= TIMESTAMP '2026-09-01'
      AND o.started_at < TIMESTAMP '2026-10-01'
    GROUP BY oi.robot_model_id
)
SELECT a.id, a.name, count(b.id) AS model_count,
       coalesce(sum(p.robots_deployed), 0) AS robots_deployed,
       coalesce(sum(p.completed_cost_pln), 0) AS completed_cost_pln
FROM public.manufacturers AS a
LEFT JOIN public.robot_models AS b ON b.manufacturer_id = a.id
LEFT JOIN completed_models AS p ON p.robot_model_id = b.id
GROUP BY a.id, a.name
ORDER BY a.id;
-- END IC8.10

-- BEGIN HW8.1
SELECT c.id AS operator_id,
       count(o.id) FILTER (WHERE o.status = 'completed') AS completed_missions,
       count(o.id) FILTER (WHERE o.status = 'queued') AS queued_missions,
       count(o.id) FILTER (WHERE o.status = 'aborted') AS aborted_missions,
       count(o.id) FILTER (WHERE o.status IS NULL) AS unknown_missions,
       count(o.id) AS total_missions,
       coalesce(sum(o.cost) FILTER (WHERE o.status = 'completed'), 0) AS completed_cost_pln
FROM public.operators AS c
LEFT JOIN public.missions AS o
  ON o.operator_id = c.id
 AND o.started_at >= TIMESTAMP '2026-09-01'
 AND o.started_at < TIMESTAMP '2026-10-01'
GROUP BY c.id
ORDER BY c.id;
-- END HW8.1

-- BEGIN HW8.2
WITH normalized AS (
    SELECT c.id, c.country, NULLIF(lower(btrim(c.email)), '') AS normalized_email
    FROM public.operators AS c
)
SELECT a.id AS operator_id_1, b.id AS operator_id_2,
       a.normalized_email, a.country
FROM normalized AS a
JOIN normalized AS b
  ON a.id < b.id AND a.normalized_email = b.normalized_email
 AND a.country IS NOT DISTINCT FROM b.country
WHERE a.normalized_email IS NOT NULL
ORDER BY a.id, b.id;
-- END HW8.2

-- BEGIN HW8.3
SELECT o.id AS mission_id, o.operator_id, previous.id AS previous_mission_id,
       round(extract(epoch FROM (o.started_at - previous.started_at)) / 3600, 2)
           AS elapsed_hours
FROM public.missions AS o
LEFT JOIN LATERAL (
    SELECT p.id, p.started_at
    FROM public.missions AS p
    WHERE p.operator_id = o.operator_id AND p.status = 'completed'
      AND (p.started_at, p.id) < (o.started_at, o.id)
    ORDER BY p.started_at DESC, p.id DESC
    LIMIT 1
) AS previous ON true
WHERE o.operator_id IS NOT NULL AND o.status = 'completed'
  AND o.started_at < TIMESTAMP '2026-10-01'
ORDER BY o.operator_id, o.started_at, o.id;
-- END HW8.3

-- BEGIN HW8.4
WITH september_tags AS (
    SELECT DISTINCT at.tag_id
    FROM public.document_tags AS at
    JOIN public.technical_documents AS a ON a.id = at.document_id
    WHERE a.published_at >= TIMESTAMP '2026-09-01'
      AND a.published_at < TIMESTAMP '2026-10-01'
)
SELECT t.id, t.name
FROM public.tags AS t
LEFT JOIN september_tags AS s ON s.tag_id = t.id
WHERE s.tag_id IS NULL
ORDER BY t.id;
-- END HW8.4

-- BEGIN HW8.5
WITH manufacturer_operators AS (
    SELECT b.manufacturer_id, o.operator_id,
           sum(oi.robot_count * oi.unit_cost) AS completed_cost_pln
    FROM public.missions AS o
    JOIN public.mission_robots AS oi ON oi.mission_id = o.id
    JOIN public.robot_models AS b ON b.id = oi.robot_model_id
    WHERE o.operator_id IS NOT NULL AND o.status = 'completed'
      AND o.started_at >= TIMESTAMP '2026-09-01'
      AND o.started_at < TIMESTAMP '2026-10-01'
    GROUP BY b.manufacturer_id, o.operator_id
)
SELECT a.id, a.name, count(ac.operator_id) AS registered_operators,
       coalesce(sum(ac.completed_cost_pln), 0) AS registered_deployment_cost_pln
FROM public.manufacturers AS a
LEFT JOIN manufacturer_operators AS ac ON ac.manufacturer_id = a.id
GROUP BY a.id, a.name
ORDER BY a.id;
-- END HW8.5

-- BEGIN HW8.6
SELECT c.id AS candidate_id, c.name,
       count(DISTINCT direct.partner_id) AS mutual_partner_count
FROM public.operator_links AS direct
JOIN public.operator_links AS second_hop ON second_hop.operator_id = direct.partner_id
JOIN public.operators AS c ON c.id = second_hop.partner_id
WHERE direct.operator_id = 1 AND second_hop.partner_id <> 1
  AND NOT EXISTS (
      SELECT 1 FROM public.operator_links AS existing
      WHERE existing.operator_id = 1 AND existing.partner_id = second_hop.partner_id
  )
GROUP BY c.id, c.name
ORDER BY mutual_partner_count DESC, c.id;
-- END HW8.6

-- BEGIN HW8.7
WITH deployments AS (
    SELECT o.operator_id, oi.robot_model_id, min(o.started_at) AS first_completed_at
    FROM public.missions AS o
    JOIN public.mission_robots AS oi ON oi.mission_id = o.id
    WHERE o.status = 'completed' AND o.operator_id IS NOT NULL
    GROUP BY o.operator_id, oi.robot_model_id
)
SELECT c.id AS operator_id, c.name AS operator_name,
       b.id AS robot_model_id, b.name AS robot_model_name,
       r.score, r.inspected_at
FROM public.inspections AS r
JOIN public.operators AS c ON c.id = r.operator_id
JOIN public.robot_models AS b ON b.id = r.robot_model_id
LEFT JOIN deployments AS p
  ON p.operator_id = r.operator_id AND p.robot_model_id = r.robot_model_id
 AND p.first_completed_at <= r.inspected_at
WHERE r.inspected_at < TIMESTAMP '2026-10-01'
  AND p.operator_id IS NULL
ORDER BY c.id, b.id;
-- END HW8.7

-- BEGIN HW8.8
SELECT c.id AS operator_id, chosen.id AS mission_id, chosen.status,
       chosen.cost, chosen.started_at
FROM public.operators AS c
LEFT JOIN LATERAL (
    SELECT o.id, o.status, o.cost, o.started_at
    FROM public.missions AS o
    WHERE o.operator_id = c.id
      AND (o.status = 'queued' OR o.status IS NULL)
      AND o.started_at < TIMESTAMP '2026-10-01'
    ORDER BY o.cost DESC, o.started_at, o.id
    LIMIT 2
) AS chosen ON true
ORDER BY c.id, chosen.cost DESC NULLS LAST,
         chosen.started_at NULLS LAST, chosen.id NULLS LAST;
-- END HW8.8

-- BEGIN HW8.9
WITH my_models AS (
    SELECT DISTINCT oi.robot_model_id
    FROM public.missions AS o
    JOIN public.mission_robots AS oi ON oi.mission_id = o.id
    WHERE o.operator_id = 1 AND o.status = 'completed'
      AND o.started_at < TIMESTAMP '2026-10-01'
)
SELECT b.id AS robot_model_id, b.name,
       count(DISTINCT f.partner_id) AS distinct_partner_operators
FROM public.operator_links AS f
JOIN public.missions AS o ON o.operator_id = f.partner_id
JOIN public.mission_robots AS oi ON oi.mission_id = o.id
JOIN public.robot_models AS b ON b.id = oi.robot_model_id
WHERE f.operator_id = 1 AND o.status = 'completed'
  AND o.started_at >= TIMESTAMP '2026-09-01'
  AND o.started_at < TIMESTAMP '2026-10-01'
  AND NOT EXISTS (SELECT 1 FROM my_models AS mine WHERE mine.robot_model_id = b.id)
GROUP BY b.id, b.name
ORDER BY distinct_partner_operators DESC, b.id
LIMIT 5;
-- END HW8.9

-- BEGIN HW8.10
WITH tag_counts AS (
    SELECT at.document_id, count(*) AS tag_count
    FROM public.document_tags AS at
    GROUP BY at.document_id
), shared AS (
    SELECT candidate.document_id, count(*) AS shared_tags
    FROM public.document_tags AS reference_tag
    JOIN public.document_tags AS candidate ON candidate.tag_id = reference_tag.tag_id
    WHERE reference_tag.document_id = 1 AND candidate.document_id <> 1
    GROUP BY candidate.document_id
), scored AS (
    SELECT s.document_id, s.shared_tags,
           candidate.tag_count + reference_count.tag_count - s.shared_tags
               AS union_tags,
           1.0 * s.shared_tags
               / (candidate.tag_count + reference_count.tag_count - s.shared_tags)
               AS exact_similarity
    FROM shared AS s
    JOIN tag_counts AS candidate ON candidate.document_id = s.document_id
    JOIN tag_counts AS reference_count ON reference_count.document_id = 1
)
SELECT a.id AS document_id, a.name, s.shared_tags, s.union_tags,
       round(s.exact_similarity, 3) AS similarity
FROM scored AS s
JOIN public.technical_documents AS a ON a.id = s.document_id
ORDER BY s.exact_similarity DESC, s.shared_tags DESC, a.id
LIMIT 5;
-- END HW8.10
