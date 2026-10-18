-- Robotics Operations Practice. PostgreSQL 17+.
-- Run once in a fresh dedicated database. Existing table names fail safely.
-- Money: PLN. Timestamps: UTC stored without time zone.
-- Fixed reporting instant: 2026-10-01 00:00:00.
BEGIN;

CREATE SCHEMA week07_lab;

CREATE TABLE public.operators (
    id integer PRIMARY KEY,
    name text NOT NULL,
    email text,
    country char(2),
    registered_at timestamp NOT NULL,
    lifetime_cost numeric(14,2) NOT NULL DEFAULT 0,
    deleted_at timestamp
);

CREATE TABLE public.missions (
    id bigint PRIMARY KEY,
    operator_id integer REFERENCES public.operators(id),
    started_at timestamp NOT NULL,
    cost numeric(12,2) NOT NULL CHECK (cost >= 0),
    status text CHECK (status IN ('completed','queued','aborted'))
);

CREATE TABLE public.manufacturers (
    id integer PRIMARY KEY,
    name text NOT NULL
);

CREATE TABLE public.robot_categories (
    id integer PRIMARY KEY,
    name text NOT NULL,
    parent_id integer REFERENCES public.robot_categories(id),
    CHECK (id <> parent_id)
);

CREATE TABLE public.robot_models (
    id integer PRIMARY KEY,
    manufacturer_id integer NOT NULL REFERENCES public.manufacturers(id),
    category_id integer REFERENCES public.robot_categories(id),
    model_code text UNIQUE NOT NULL,
    name text NOT NULL,
    unit_cost numeric(10,2) NOT NULL CHECK (unit_cost >= 0)
);

CREATE TABLE public.mission_robots (
    mission_id bigint REFERENCES public.missions(id),
    robot_model_id integer REFERENCES public.robot_models(id),
    robot_count integer NOT NULL CHECK (robot_count > 0),
    unit_cost numeric(10,2) NOT NULL CHECK (unit_cost >= 0),
    PRIMARY KEY (mission_id,robot_model_id)
);

CREATE TABLE public.inspections (
    operator_id integer REFERENCES public.operators(id),
    robot_model_id integer REFERENCES public.robot_models(id),
    score smallint NOT NULL CHECK (score BETWEEN 1 AND 5),
    inspected_at timestamp NOT NULL,
    PRIMARY KEY (operator_id,robot_model_id)
);

CREATE TABLE public.robot_inventory_morning (
    robot_model_id integer PRIMARY KEY REFERENCES public.robot_models(id),
    available_units integer CHECK (available_units >= 0)
);

CREATE TABLE public.robot_inventory_evening (
    robot_model_id integer PRIMARY KEY REFERENCES public.robot_models(id),
    available_units integer CHECK (available_units >= 0)
);

CREATE TABLE public.technical_documents (
    id integer PRIMARY KEY,
    name text NOT NULL,
    published_at timestamp NOT NULL
);

CREATE TABLE public.tags (
    id integer PRIMARY KEY,
    name text UNIQUE NOT NULL
);

CREATE TABLE public.document_tags (
    document_id integer REFERENCES public.technical_documents(id),
    tag_id integer REFERENCES public.tags(id),
    PRIMARY KEY (document_id,tag_id)
);

CREATE TABLE public.operator_links (
    operator_id integer REFERENCES public.operators(id),
    partner_id integer REFERENCES public.operators(id),
    PRIMARY KEY (operator_id,partner_id),
    CHECK (operator_id <> partner_id)
);

CREATE TABLE public.robot_metrics (
    day date,
    metric text CHECK (metric IN ('sensor_reads','faults','missions')),
    value numeric(12,2),
    PRIMARY KEY (day,metric)
);

CREATE TABLE public.sensor_readings (
    id integer PRIMARY KEY,
    value numeric
);

-- Contact anomalies are intentional; blank text and SQL NULL are distinct.
INSERT INTO public.operators VALUES
 (1,'Baltic Robotics','Ops@BalticRobotics.pl','PL','2025-12-08 09:00:00',0,NULL),
 (2,'Baltic Robotics Lab',' ops@balticrobot_models.PL ','PL','2025-12-19 10:00:00',0,NULL),
 (3,'Baltic Robotics DE','OPS@BALTICBOOKS.PL','DE','2026-01-05 11:00:00',0,'2026-09-29 12:00:00'),
 (4,'Amber Automation',NULL,'PL','2026-01-08 12:00:00',0,NULL),
 (5,'River Robot Lab','','PL','2026-01-12 09:00:00',0,NULL),
 (6,'Loft Robotics','   ','CZ','2026-01-17 09:00:00',0,NULL),
 (7,'Meridian Robotics','Contact@Meridian.example',NULL,'2026-01-20 10:00:00',0,NULL),
 (8,'Meridian Prototype Lab',' contact@meridian.EXAMPLE ',NULL,'2026-01-22 14:00:00',0,'2026-09-29 14:00:00'),
 (9,'Juniper Automation','  READ@JUNIPER.example  ','PL','2026-02-01 09:00:00',0,NULL),
 (10,'Forge Robotics','missionsforge.example','DE','2026-02-04 09:00:00',0,NULL),
 (11,'Vistula Robot Lab','reading@@vistula.example','PL','2026-02-08 13:00:00',0,NULL),
 (12,'Copper Robotics','.library@copper.example','CZ','2026-02-10 12:00:00',0,NULL),
 (13,'Forest Automation','missions..team@forest.example','SK','2026-02-14 10:00:00',0,NULL),
 (14,'Pixel Robotics','Learning@Pixel.example.','PL','2026-02-18 11:00:00',0,NULL),
 (15,'North Robotics','reading team@north.example','DE','2026-02-21 12:00:00',0,NULL),
 (16,'Stone Automation','office@stone.example','PL','2026-02-25 10:00:00',0,NULL),
 (17,'Paper Drone Lab','missions@paperkite.example','CZ','2026-03-01 09:00:00',0,NULL),
 (18,'Cobalt Robotics','reading@cobalt.example','PL','2026-03-03 13:00:00',0,NULL),
 (19,'Maple Robot Research','library@maple.example','SK','2026-03-07 11:00:00',0,NULL),
 (20,'Harbour Automation','robot_models@harbour.example','PL','2026-03-10 12:00:00',0,'2026-08-01 12:00:00'),
 (21,'Vector Robotics','OPS@VECTOR.example ','DE','2026-03-14 09:00:00',0,NULL),
 (22,'Quiet Robotics','read@quiethome.example','PL','2026-03-18 09:00:00',0,NULL),
 (23,'Orion Robotics Lab','lab@orion.example',NULL,'2026-03-22 14:00:00',0,NULL),
 (24,'New Robotics Team',NULL,'PL','2026-09-15 10:00:00',0,NULL);

-- 180 regular missions: 30 per month, April through September.
-- Operator 5 has missions but no completed mission; operator 20 has none.
WITH seed AS (
    SELECT n,
           CASE WHEN n % 17 = 0 THEN NULL
                WHEN 1 + ((n * 7) % 22) IN (20,22) THEN 1
                ELSE 1 + ((n * 7) % 22) END AS operator_id,
           TIMESTAMP '2026-04-01 00:00:00'
             + ((n-1)/30) * INTERVAL '1 month'
             + ((n-1)%25) * INTERVAL '1 day'
             + ((n*7)%20) * INTERVAL '1 hour'
             + ((n*13)%60) * INTERVAL '1 minute' AS started_at,
           CASE n % 10 WHEN 0 THEN 'aborted'
                       WHEN 1 THEN 'queued'
                       WHEN 2 THEN 'queued'
                       WHEN 3 THEN NULL ELSE 'completed' END AS status
    FROM generate_series(1,180) AS g(n)
)
INSERT INTO public.missions
SELECT n, operator_id, started_at, (35+((n*29)%430))::numeric(12,2),
       CASE WHEN operator_id=5 AND status='completed' THEN 'queued' ELSE status END
FROM seed;

INSERT INTO public.missions VALUES
 (1001,1,'2026-09-01 00:00:00',0.00,'completed'),
 (1002,1,'2026-09-01 00:00:00',50.00,'completed'),
 (1003,2,'2026-09-01 00:00:00',100.00,'completed'),
 (1004,2,'2026-09-02 12:00:00',1500.00,'completed'),
 (1005,3,'2026-09-03 09:00:00',1000.00,'completed'),
 (1006,3,'2026-09-03 09:00:00',1000.00,'completed'),
 (1007,4,'2026-09-04 10:00:00',1500.00,'completed'),
 (1008,5,'2026-09-07 10:00:00',50.00,'queued'),
 (1009,6,'2026-09-08 10:00:00',100.00,NULL),
 (1010,NULL,'2026-09-10 08:00:00',500.00,'completed'),
 (1011,7,'2026-09-11 09:00:00',125.00,'completed'),
 (1012,8,'2026-09-14 09:00:00',200.00,'completed'),
 (1013,9,'2026-09-15 09:00:00',300.00,'completed'),
 (1014,10,'2026-09-17 09:00:00',150.00,'aborted'),
 (1015,11,'2026-09-18 09:00:00',275.00,'completed'),
 (1016,12,'2026-09-21 09:00:00',99.99,'completed'),
 (1017,13,'2026-09-22 09:00:00',100.01,'completed'),
 (1018,14,'2026-09-24 09:00:00',499.99,'completed'),
 (1019,15,'2026-09-25 09:00:00',500.01,'completed'),
 (1020,16,'2026-09-27 09:00:00',999.99,'completed'),
 (1021,17,'2026-09-28 09:00:00',1000.01,'completed'),
 (1022,18,'2026-09-29 09:00:00',250.00,'completed'),
 (1023,19,'2026-09-30 00:00:00',250.00,'queued'),
 (1024,21,'2026-09-30 23:59:59',100.00,'queued'),
 (1025,21,'2026-09-30 23:30:00',50.00,'queued'),
 (1026,21,'2026-09-30 23:59:00',0.00,NULL),
 (1027,22,'2026-04-01 00:00:00',40.00,'completed'),
 (1028,23,'2026-08-31 23:59:59',60.00,'completed'),
 (1029,21,'2026-09-01 00:00:00',80.00,'aborted'),
 (1030,NULL,'2026-09-30 23:59:59',75.00,'queued');

-- Lifetime value is the sum of this operator's completed mission costs.
UPDATE public.operators AS c
SET lifetime_cost = COALESCE((
    SELECT SUM(o.cost) FROM public.missions AS o
    WHERE o.operator_id=c.id AND o.status='completed'
),0);

INSERT INTO public.manufacturers VALUES
 (1,'Astra Robotics'), (2,'Vector Motion'), (3,'Helix Automation'),
 (4,'Nord Robot Systems'), (5,'Orion Manufacturing'), (6,'Prototype Robotics');

INSERT INTO public.robot_categories VALUES
 (1,'Industrial Robots',NULL), (2,'Service Robots',NULL),
 (3,'Mobile Platforms',1), (4,'Manipulators',1), (5,'Autonomous Systems',1),
 (6,'Inspection Drones',5), (7,'Warehouse Robots',5), (8,'Cleaning Robots',2),
 (9,'Experimental Models',NULL);

INSERT INTO public.robot_models VALUES
 (1,1,3,'9780000000001','RX_100 Scout',79.90),
 (2,1,4,'9780000000002','ArmPro 200',119.00),
 (3,2,3,'9780000000003','Rover X3',149.00),
 (4,2,5,'9780000000004','Precision 100%',99.00),
 (5,3,6,'9780000000005','Inspection Drones Systems Workrobot_model',199.00),
 (6,3,4,'9780000000006','GripMate 6',89.00),
 (7,4,7,'9780000000007','CargoBot 7',139.00),
 (8,4,5,'9780000000008','RouteRunner 8',129.00),
 (9,5,3,'9780000000009','VisionCart 9',169.00),
 (10,5,8,'9780000000010','CleanBot 10',59.00),
 (11,2,NULL,'9780000000011','Operations Handrobot_model',49.00),
 (12,5,8,'9780000000012','Prototype 12',159.00);

-- Historical line unit_costs reconcile exactly with every mission total.
-- Multiples of three have two distinct robot_models; some other missions have robot_count2.
WITH lines AS (
    SELECT id, cost,
           (id%3=0 AND cost>=20) AS split,
           CASE WHEN id%4=0 AND round(cost/2,2)*2=cost
                THEN 2 ELSE 1 END AS robot_count
    FROM public.missions
)
INSERT INTO public.mission_robots
SELECT id, 1+(id%11)::integer,
       CASE WHEN split THEN 1 ELSE robot_count END,
       CASE WHEN split THEN cost-10 ELSE cost/robot_count END
FROM lines
UNION ALL
SELECT id, 1+((id+4)%11)::integer, 1, 10.00
FROM lines WHERE split;

-- Inspections do not imply prior deployment. Model12 is uninspected and unused.
INSERT INTO public.inspections
SELECT 1+((robot_model_id*3+slot*7)%19), robot_model_id,
       (1+((robot_model_id+slot)%5))::smallint,
       TIMESTAMP '2026-09-27 10:00:00' + robot_model_id*INTERVAL '1 hour'
FROM generate_series(1,11) AS robot_models(robot_model_id)
CROSS JOIN generate_series(0,1) AS slots(slot);

INSERT INTO public.inspections VALUES
 (24,1,5,'2026-09-28 10:00:00'),
 (20,2,2,'2026-09-28 11:00:00'),
 (1,3,5,'2026-09-28 12:00:00'),
 (1,5,4,'2026-09-28 13:00:00'),
 (2,3,3,'2026-09-28 14:00:00');

INSERT INTO public.robot_inventory_morning VALUES
 (1,NULL),(2,NULL),(3,0),(4,4),(5,7),(6,5),(7,3),(8,NULL),(9,NULL);

INSERT INTO public.robot_inventory_evening VALUES
 (1,0),(2,NULL),(3,0),(4,2),(6,8),(7,3),(8,NULL),(10,0),(11,NULL);

INSERT INTO public.technical_documents VALUES
 (1,'Reconciling Mission Costs','2026-06-01 09:00:00'),
 (2,'Missing Sensor Values','2026-06-08 09:00:00'),
 (3,'Robot Model Hierarchies','2026-06-15 09:00:00'),
 (4,'Late Sensor Packets','2026-07-01 09:00:00'),
 (5,'Robot Fleet Data Models','2026-07-08 09:00:00'),
 (6,'Safe Telemetry UPSERTs','2026-07-15 09:00:00'),
 (7,'Robot Inventory Differences','2026-08-01 09:00:00'),
 (8,'Operator Contact Validation','2026-08-08 09:00:00'),
 (9,'Ranking Mission Costs','2026-08-15 09:00:00'),
 (10,'Atomic Mission Updates','2026-09-01 09:00:00'),
 (11,'Telemetry Query Plans','2026-09-15 09:00:00'),
 (12,'Robot Release Checklist','2026-09-30 09:00:00');

INSERT INTO public.tags VALUES
 (1,'robotics'),(2,'postgrerobotics'),(3,'safety'),(4,'model_design'),
 (5,'navigation'),(6,'telemetry'),(7,'maintenance'),(8,'unused');

INSERT INTO public.document_tags VALUES
 (1,1),(1,2),(1,3),(2,1),(2,3),(3,1),(3,4),(4,2),(4,6),
 (5,3),(5,4),(6,1),(6,2),(6,7),(7,1),(7,3),(8,3),(8,6),
 (9,1),(9,5),(10,2),(10,7),(11,2),(11,5);

-- Symmetric storage: insert each undirected pair in both directions.
WITH pairs(a,b) AS (
    VALUES (1,2),(1,3),(1,4),(2,3),(2,5),(2,6),
           (3,6),(3,7),(4,8),(5,9),(6,10),(7,8)
)
INSERT INTO public.operator_links
SELECT a,b FROM pairs
UNION ALL
SELECT b,a FROM pairs;

-- Sparse metrics. A NULL observation, a stored zero, and a missing row differ.
INSERT INTO public.robot_metrics
SELECT d::date, m.metric,
       CASE WHEN (d::date=DATE '2026-09-27' AND m.metric='faults')
                   OR (d::date=DATE '2026-09-30' AND m.metric='missions')
            THEN NULL
            WHEN d::date=DATE '2026-09-25' AND m.metric='sensor_reads' THEN 0
            WHEN m.metric='sensor_reads' THEN (EXTRACT(day FROM d)::integer*7)%100
            WHEN m.metric='faults' THEN EXTRACT(day FROM d)::integer%5
            ELSE EXTRACT(day FROM d)::integer%7 END
FROM generate_series(DATE '2026-09-24',DATE '2026-09-30',INTERVAL '1 day') AS dates(d)
CROSS JOIN (VALUES ('sensor_reads'),('faults'),('missions')) AS m(metric)
WHERE d::date<>DATE '2026-09-26'
  AND NOT (d::date=DATE '2026-09-28' AND m.metric='missions')
  AND NOT (d::date=DATE '2026-09-29' AND m.metric='faults');

INSERT INTO public.sensor_readings VALUES (1,10),(2,20),(3,NULL),(4,30),(5,NULL);

COMMIT;
