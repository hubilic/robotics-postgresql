-- Week07 answers: execute each block inside BEGIN / ROLLBACK in one connection.

-- BEGIN IC7.1
CREATE TABLE week07_lab.ic71_robots(
 id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 serial_number varchar(24) NOT NULL UNIQUE CHECK(btrim(serial_number)<>''),
 model_name text NOT NULL, commissioned_on date NOT NULL,
 is_active boolean NOT NULL DEFAULT true,
 maximum_payload_kg numeric(8,2) NOT NULL CHECK(maximum_payload_kg>0),
 calibration_notes text);
INSERT INTO week07_lab.ic71_robots(serial_number,model_name,commissioned_on,maximum_payload_kg)
VALUES('RB-001','Scout','2026-09-01',5),('RB-002','Cargo','2026-09-02',40);
-- CHECK accepts UNKNOWN; NOT NULL is needed for required values.
DO $$ BEGIN
 BEGIN INSERT INTO week07_lab.ic71_robots(serial_number,model_name,commissioned_on,maximum_payload_kg)
 VALUES('BAD-NULL','Scout','2026-09-01',NULL);RAISE EXCEPTION 'Expected failure';
 EXCEPTION WHEN not_null_violation THEN NULL;END;
 BEGIN INSERT INTO week07_lab.ic71_robots(serial_number,model_name,commissioned_on,maximum_payload_kg)
 VALUES('BAD-ZERO','Scout','2026-09-01',0);RAISE EXCEPTION 'Expected failure';
 EXCEPTION WHEN check_violation THEN NULL;END;
END $$;
SELECT serial_number,model_name,is_active,maximum_payload_kg FROM week07_lab.ic71_robots ORDER BY serial_number;
-- END IC7.1

-- BEGIN IC7.2
CREATE TABLE week07_lab.ic72_operators(id integer PRIMARY KEY,name text NOT NULL);
CREATE TABLE week07_lab.ic72_certifications(id integer PRIMARY KEY,name text NOT NULL);
CREATE TABLE week07_lab.ic72_operator_certifications(
 operator_id integer REFERENCES week07_lab.ic72_operators(id),
 certification_id integer REFERENCES week07_lab.ic72_certifications(id),awarded_on date NOT NULL,
 PRIMARY KEY(operator_id,certification_id));
INSERT INTO week07_lab.ic72_operators VALUES(1,'Anna'),(2,'Piotr');
INSERT INTO week07_lab.ic72_certifications VALUES(1,'Drone safety'),(2,'Arm calibration');
INSERT INTO week07_lab.ic72_operator_certifications VALUES(1,1,'2026-09-01'),(1,2,'2026-09-02'),(2,1,'2026-09-03');
DO $$ BEGIN
 BEGIN INSERT INTO week07_lab.ic72_operator_certifications VALUES(1,1,'2026-09-04');RAISE EXCEPTION 'Expected duplicate';
 EXCEPTION WHEN unique_violation THEN NULL;END;
 BEGIN INSERT INTO week07_lab.ic72_operator_certifications VALUES(2,99,'2026-09-04');RAISE EXCEPTION 'Expected missing certification';
 EXCEPTION WHEN foreign_key_violation THEN NULL;END;
END $$;
SELECT o.id,o.name,count(c.certification_id) AS certifications FROM week07_lab.ic72_operators o
LEFT JOIN week07_lab.ic72_operator_certifications c ON c.operator_id=o.id GROUP BY o.id,o.name ORDER BY o.id;
-- END IC7.2

-- BEGIN IC7.3
CREATE TABLE week07_lab.ic73_contacts(id integer PRIMARY KEY,operator_name text NOT NULL,email text,is_active boolean NOT NULL DEFAULT true);
CREATE UNIQUE INDEX ic73_email_uq ON week07_lab.ic73_contacts((lower(btrim(email))))
WHERE is_active AND nullif(btrim(email),'') IS NOT NULL;
INSERT INTO week07_lab.ic73_contacts VALUES(1,'Robot Lab A',' Ops@Lab.example ',true),(2,'Robot Lab Archive','ops@lab.example',false),(3,'No email',NULL,true),(4,'Blank email','   ',true),(5,'Empty email','',true);
DO $$ BEGIN
 BEGIN UPDATE week07_lab.ic73_contacts SET is_active=true WHERE id=2;RAISE EXCEPTION 'Expected duplicate';
 EXCEPTION WHEN unique_violation THEN NULL;END;
END $$;
SELECT id,operator_name,email,nullif(lower(btrim(email)),'') AS normalized_email,is_active FROM week07_lab.ic73_contacts ORDER BY id;
-- END IC7.3

-- BEGIN IC7.4
CREATE TABLE week07_lab.ic74_maintenance_windows(id integer PRIMARY KEY,start_at timestamp NOT NULL,end_at timestamp NOT NULL,inspection_at timestamp,
 CHECK(end_at>=start_at AND end_at<=start_at+interval '14 days'),CHECK(inspection_at BETWEEN start_at AND end_at));
INSERT INTO week07_lab.ic74_maintenance_windows VALUES(1,'2026-09-01','2026-09-01',NULL),(2,'2026-09-01','2026-09-15','2026-09-15');
DO $$ BEGIN
 BEGIN INSERT INTO week07_lab.ic74_maintenance_windows VALUES(3,'2026-09-02','2026-09-01',NULL);RAISE EXCEPTION 'Expected reversed failure';EXCEPTION WHEN check_violation THEN NULL;END;
 BEGIN INSERT INTO week07_lab.ic74_maintenance_windows VALUES(4,'2026-09-01','2026-09-15 00:00:01',NULL);RAISE EXCEPTION 'Expected duration failure';EXCEPTION WHEN check_violation THEN NULL;END;
 BEGIN INSERT INTO week07_lab.ic74_maintenance_windows VALUES(5,'2026-09-01','2026-09-02','2026-09-03');RAISE EXCEPTION 'Expected inspection failure';EXCEPTION WHEN check_violation THEN NULL;END;
END $$;
SELECT id,start_at,end_at,end_at-start_at AS duration,inspection_at FROM week07_lab.ic74_maintenance_windows ORDER BY id;
-- END IC7.4

-- BEGIN IC7.5
CREATE TABLE week07_lab.ic75_robots(id integer PRIMARY KEY);
CREATE TABLE week07_lab.ic75_no_action(id integer PRIMARY KEY,robot_id integer NOT NULL REFERENCES week07_lab.ic75_robots ON DELETE NO ACTION);
CREATE TABLE week07_lab.ic75_restrict(id integer PRIMARY KEY,robot_id integer NOT NULL REFERENCES week07_lab.ic75_robots ON DELETE RESTRICT);
CREATE TABLE week07_lab.ic75_cascade(id integer PRIMARY KEY,robot_id integer NOT NULL REFERENCES week07_lab.ic75_robots ON DELETE CASCADE);
CREATE TABLE week07_lab.ic75_set_null(id integer PRIMARY KEY,robot_id integer REFERENCES week07_lab.ic75_robots ON DELETE SET NULL);
INSERT INTO week07_lab.ic75_robots VALUES(1),(2),(3),(4);
INSERT INTO week07_lab.ic75_no_action VALUES(1,1);INSERT INTO week07_lab.ic75_restrict VALUES(2,2);
INSERT INTO week07_lab.ic75_cascade VALUES(3,3);INSERT INTO week07_lab.ic75_set_null VALUES(4,4);
DO $$ BEGIN
 BEGIN DELETE FROM week07_lab.ic75_robots WHERE id=1;RAISE EXCEPTION 'Expected NO ACTION failure';EXCEPTION WHEN foreign_key_violation THEN NULL;END;
 BEGIN DELETE FROM week07_lab.ic75_robots WHERE id=2;RAISE EXCEPTION 'Expected RESTRICT failure';EXCEPTION WHEN restrict_violation OR foreign_key_violation THEN NULL;END;
END $$;
DELETE FROM week07_lab.ic75_robots WHERE id IN(3,4);
-- NO ACTION can be DEFERRABLE; RESTRICT cannot defer its delete check.
-- SET NULL must be allowed by the child column's nullability.
SELECT 'NO ACTION' AS rule,count(*) AS children,count(robot_id) AS references_left FROM week07_lab.ic75_no_action
UNION ALL SELECT 'RESTRICT',count(*),count(robot_id) FROM week07_lab.ic75_restrict
UNION ALL SELECT 'CASCADE',count(*),count(robot_id) FROM week07_lab.ic75_cascade
UNION ALL SELECT 'SET NULL',count(*),count(robot_id) FROM week07_lab.ic75_set_null ORDER BY rule;
-- END IC7.5

-- BEGIN IC7.6
CREATE TABLE week07_lab.ic76_onboarding(operator_id integer PRIMARY KEY REFERENCES public.operators(id),email text NOT NULL CHECK(btrim(email)<>''),created_at timestamp NOT NULL);
INSERT INTO week07_lab.ic76_onboarding SELECT id,lower(btrim(email)),timestamp '2026-10-01' FROM public.operators o
WHERE deleted_at IS NULL AND nullif(btrim(email),'') IS NOT NULL AND NOT EXISTS(SELECT 1 FROM week07_lab.ic76_onboarding n WHERE n.operator_id=o.id) ON CONFLICT(operator_id) DO NOTHING;
DO $$ DECLARE n bigint;BEGIN
 INSERT INTO week07_lab.ic76_onboarding SELECT id,lower(btrim(email)),timestamp '2026-10-01' FROM public.operators o
 WHERE deleted_at IS NULL AND nullif(btrim(email),'') IS NOT NULL AND NOT EXISTS(SELECT 1 FROM week07_lab.ic76_onboarding n WHERE n.operator_id=o.id) ON CONFLICT(operator_id) DO NOTHING;
 GET DIAGNOSTICS n=ROW_COUNT;IF n<>0 THEN RAISE EXCEPTION 'Replay inserted % rows',n;END IF;
END $$;
SELECT count(*) AS onboarding_records FROM week07_lab.ic76_onboarding;
-- END IC7.6

-- BEGIN IC7.7
CREATE TABLE week07_lab.ic77_operator_costs(operator_id integer PRIMARY KEY REFERENCES public.operators(id),completed_cost numeric(14,2) NOT NULL CHECK(completed_cost>=0));
INSERT INTO week07_lab.ic77_operator_costs SELECT id,999 FROM public.operators;
UPDATE week07_lab.ic77_operator_costs t SET completed_cost=s.cost FROM
(SELECT o.id,coalesce(sum(m.cost) FILTER(WHERE m.status='completed'),0) AS cost FROM public.operators o LEFT JOIN public.missions m ON m.operator_id=o.id GROUP BY o.id) s WHERE t.operator_id=s.id;
DO $$ BEGIN IF EXISTS(SELECT 1 FROM week07_lab.ic77_operator_costs t WHERE t.completed_cost IS DISTINCT FROM
(SELECT coalesce(sum(cost),0) FROM public.missions m WHERE m.operator_id=t.operator_id AND status='completed')) THEN RAISE EXCEPTION 'Wrong summary';END IF;END $$;
SELECT * FROM week07_lab.ic77_operator_costs ORDER BY operator_id;
-- END IC7.7

-- BEGIN IC7.8
CREATE TABLE week07_lab.ic78_operator_costs AS SELECT id,lifetime_cost FROM public.operators;
SELECT * FROM week07_lab.ic78_operator_costs ORDER BY lifetime_cost,id LIMIT (SELECT floor(count(*)*0.10)::integer FROM week07_lab.ic78_operator_costs);
DELETE FROM week07_lab.ic78_operator_costs WHERE id IN(SELECT id FROM week07_lab.ic78_operator_costs ORDER BY lifetime_cost,id LIMIT(SELECT floor(count(*)*0.10)::integer FROM week07_lab.ic78_operator_costs)) RETURNING id,lifetime_cost;
DO $$ BEGIN IF(SELECT count(*) FROM week07_lab.ic78_operator_costs)<>(SELECT count(*)-floor(count(*)*0.10)::integer FROM public.operators) THEN RAISE EXCEPTION 'Wrong cleanup count';END IF;END $$;
SELECT count(*) AS remaining FROM week07_lab.ic78_operator_costs;
-- END IC7.8

-- BEGIN IC7.9
CREATE TABLE week07_lab.ic79_parts(id integer PRIMARY KEY,name text NOT NULL);
CREATE TABLE week07_lab.ic79_variants(id integer PRIMARY KEY,part_id integer NOT NULL REFERENCES week07_lab.ic79_parts(id),voltage integer NOT NULL CHECK(voltage>0),connector text NOT NULL,sku text NOT NULL UNIQUE,stock integer NOT NULL CHECK(stock>=0),UNIQUE(part_id,voltage,connector));
INSERT INTO week07_lab.ic79_parts VALUES(1,'Motor'),(2,'Sensor');
INSERT INTO week07_lab.ic79_variants VALUES(1,1,12,'A','M12A',5),(2,1,24,'A','M24A',2),(3,2,5,'B','S5B',0);
DO $$ BEGIN
 BEGIN INSERT INTO week07_lab.ic79_variants VALUES(4,2,5,'C','NEG',-1);RAISE EXCEPTION 'Expected negative stock';EXCEPTION WHEN check_violation THEN NULL;END;
 BEGIN INSERT INTO week07_lab.ic79_variants VALUES(5,1,12,'A','DUP',1);RAISE EXCEPTION 'Expected duplicate variant';EXCEPTION WHEN unique_violation THEN NULL;END;
END $$;
SELECT p.id,p.name,coalesce(sum(v.stock),0) AS total_stock FROM week07_lab.ic79_parts p LEFT JOIN week07_lab.ic79_variants v ON v.part_id=p.id GROUP BY p.id,p.name ORDER BY p.id;
-- END IC7.9

-- BEGIN IC7.10
CREATE TABLE week07_lab.ic710_parts(id integer PRIMARY KEY,name text NOT NULL,list_price numeric(10,2) NOT NULL CHECK(list_price>=0));
CREATE TABLE week07_lab.ic710_missions(id integer PRIMARY KEY,started_at timestamp NOT NULL);
CREATE TABLE week07_lab.ic710_mission_parts(mission_id integer REFERENCES week07_lab.ic710_missions(id),part_id integer REFERENCES week07_lab.ic710_parts(id),quantity integer NOT NULL CHECK(quantity>0),unit_cost numeric(10,2) NOT NULL CHECK(unit_cost>=0),PRIMARY KEY(mission_id,part_id));
INSERT INTO week07_lab.ic710_parts VALUES(1,'Motor',45),(2,'Sensor',12);INSERT INTO week07_lab.ic710_missions VALUES(1,'2026-09-01');
INSERT INTO week07_lab.ic710_mission_parts VALUES(1,1,2,40),(1,2,3,10);
-- The billed unit_cost is a historical snapshot; list_price can change independently.
SELECT m.id,coalesce(sum(p.quantity*p.unit_cost),0) AS mission_cost FROM week07_lab.ic710_missions m LEFT JOIN week07_lab.ic710_mission_parts p ON p.mission_id=m.id GROUP BY m.id ORDER BY m.id;
-- END IC7.10

-- BEGIN HW7.1
CREATE TABLE week07_lab.hw71_flat(mission_id integer,operator_id integer,model_id integer,cost numeric(10,2));
INSERT INTO week07_lab.hw71_flat VALUES(1,10,100,40),(1,10,101,60),(2,20,100,50);
CREATE TABLE week07_lab.hw71_operators(id integer PRIMARY KEY);
CREATE TABLE week07_lab.hw71_missions(id integer PRIMARY KEY,operator_id integer NOT NULL REFERENCES week07_lab.hw71_operators(id));
CREATE TABLE week07_lab.hw71_lines(mission_id integer REFERENCES week07_lab.hw71_missions(id),model_id integer,cost numeric(10,2) NOT NULL CHECK(cost>=0),PRIMARY KEY(mission_id,model_id));
INSERT INTO week07_lab.hw71_operators SELECT DISTINCT operator_id FROM week07_lab.hw71_flat;
INSERT INTO week07_lab.hw71_missions SELECT DISTINCT mission_id,operator_id FROM week07_lab.hw71_flat;
INSERT INTO week07_lab.hw71_lines SELECT mission_id,model_id,cost FROM week07_lab.hw71_flat;
DO $$ BEGIN IF(SELECT count(*) FROM week07_lab.hw71_operators)<>2 OR(SELECT count(*) FROM week07_lab.hw71_missions)<>2 OR(SELECT count(*) FROM week07_lab.hw71_lines)<>3 OR(SELECT sum(cost) FROM week07_lab.hw71_lines)<>150 THEN RAISE EXCEPTION 'Migration reconciliation failed';END IF;END $$;
SELECT mission_id,sum(cost) AS mission_cost FROM week07_lab.hw71_lines GROUP BY mission_id ORDER BY mission_id;
-- END HW7.1

-- BEGIN HW7.2
CREATE TABLE week07_lab.hw72_robots(id integer PRIMARY KEY,name text NOT NULL,deleted_at timestamp);
INSERT INTO week07_lab.hw72_robots VALUES(1,'Scout',NULL),(2,'Cargo','2026-07-01'),(3,'Drone','2026-09-01');
CREATE VIEW week07_lab.hw72_active_robots AS SELECT * FROM week07_lab.hw72_robots WHERE deleted_at IS NULL;
UPDATE week07_lab.hw72_robots SET deleted_at=timestamp '2026-10-01' WHERE id=1;
DELETE FROM week07_lab.hw72_robots WHERE deleted_at<timestamp '2026-10-01'-interval '90 days';
-- The view hides soft-deleted rows; storage retention is independent.
DO $$ BEGIN IF(SELECT count(*) FROM week07_lab.hw72_robots)<>2 OR EXISTS(SELECT 1 FROM week07_lab.hw72_active_robots) THEN RAISE EXCEPTION 'Wrong retention result';END IF;END $$;
SELECT * FROM week07_lab.hw72_robots ORDER BY id;
-- END HW7.2

-- BEGIN HW7.3
CREATE TABLE week07_lab.hw73_configs(robot_id integer PRIMARY KEY,speed_limit numeric NOT NULL CHECK(speed_limit>0));
CREATE TABLE week07_lab.hw73_history(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,robot_id integer NOT NULL,old_speed numeric NOT NULL,changed_at timestamp NOT NULL);
CREATE FUNCTION week07_lab.hw73_audit() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN
 INSERT INTO week07_lab.hw73_history(robot_id,old_speed,changed_at) VALUES(OLD.robot_id,OLD.speed_limit,current_timestamp AT TIME ZONE 'UTC');RETURN NEW;END $$;
CREATE TRIGGER hw73_capture AFTER UPDATE ON week07_lab.hw73_configs FOR EACH ROW WHEN(OLD.speed_limit IS DISTINCT FROM NEW.speed_limit) EXECUTE FUNCTION week07_lab.hw73_audit();
INSERT INTO week07_lab.hw73_configs VALUES(1,10);UPDATE week07_lab.hw73_configs SET speed_limit=10 WHERE robot_id=1;UPDATE week07_lab.hw73_configs SET speed_limit=15 WHERE robot_id=1;UPDATE week07_lab.hw73_configs SET speed_limit=20 WHERE robot_id=1;
DO $$ BEGIN IF(SELECT array_agg(old_speed ORDER BY id) FROM week07_lab.hw73_history) IS DISTINCT FROM ARRAY[10,15]::numeric[] OR(SELECT speed_limit FROM week07_lab.hw73_configs WHERE robot_id=1) IS DISTINCT FROM 20 THEN RAISE EXCEPTION 'Bad audit';END IF;END $$;
SELECT robot_id,old_speed FROM week07_lab.hw73_history ORDER BY id;
-- END HW7.3

-- BEGIN HW7.4
CREATE TABLE week07_lab.hw74_metrics(robot_id integer,metric_day date,value numeric NOT NULL,source_updated_at timestamp NOT NULL,PRIMARY KEY(robot_id,metric_day));
INSERT INTO week07_lab.hw74_metrics VALUES(1,'2026-09-30',10,'2026-09-30 10:00');
INSERT INTO week07_lab.hw74_metrics AS t VALUES(1,'2026-09-30',20,'2026-09-30 11:00') ON CONFLICT(robot_id,metric_day) DO UPDATE SET value=EXCLUDED.value,source_updated_at=EXCLUDED.source_updated_at WHERE EXCLUDED.source_updated_at>t.source_updated_at;
INSERT INTO week07_lab.hw74_metrics AS t VALUES(1,'2026-09-30',99,'2026-09-30 09:00') ON CONFLICT(robot_id,metric_day) DO UPDATE SET value=EXCLUDED.value,source_updated_at=EXCLUDED.source_updated_at WHERE EXCLUDED.source_updated_at>t.source_updated_at;
DO $$ DECLARE n bigint;BEGIN
 INSERT INTO week07_lab.hw74_metrics AS t VALUES(1,'2026-09-30',20,'2026-09-30 11:00') ON CONFLICT(robot_id,metric_day) DO UPDATE SET value=EXCLUDED.value,source_updated_at=EXCLUDED.source_updated_at WHERE EXCLUDED.source_updated_at>t.source_updated_at;
 GET DIAGNOSTICS n=ROW_COUNT;IF n<>0 OR(SELECT value FROM week07_lab.hw74_metrics WHERE robot_id=1) IS DISTINCT FROM 20 THEN RAISE EXCEPTION 'Replay changed state';END IF;
END $$;
SELECT * FROM week07_lab.hw74_metrics;
-- END HW7.4

-- BEGIN HW7.5
CREATE TABLE week07_lab.hw75_families(id integer PRIMARY KEY,name text NOT NULL,parent_id integer REFERENCES week07_lab.hw75_families(id),CHECK(id<>parent_id));
INSERT INTO week07_lab.hw75_families VALUES(1,'Autonomous Systems',NULL),(2,'Mobile Robots',1),(3,'Inspection Rovers',2);
DO $$ BEGIN BEGIN UPDATE week07_lab.hw75_families SET parent_id=3 WHERE id=3;RAISE EXCEPTION 'Expected self-parent failure';EXCEPTION WHEN check_violation THEN NULL;END;END $$;
-- CHECK examines one row, so a multi-row cycle needs a recursive cycle check
-- in a trigger, together with concurrency control that serializes hierarchy edits.
SELECT c.id,c.name,p.name AS parent_name FROM week07_lab.hw75_families c LEFT JOIN week07_lab.hw75_families p ON p.id=c.parent_id ORDER BY c.id;
-- END HW7.5

-- BEGIN HW7.6
CREATE TABLE week07_lab.hw76_robots(id integer PRIMARY KEY,full_name text NOT NULL);
INSERT INTO week07_lab.hw76_robots VALUES(1,'Scout One');
CREATE VIEW week07_lab.hw76_old_robots AS SELECT id,full_name FROM week07_lab.hw76_robots;
-- Deploy old clients against this view before renaming the base column.
-- ALTER TABLE needs a short strong lock: deploy during a controlled migration.
ALTER TABLE week07_lab.hw76_robots RENAME COLUMN full_name TO name;
CREATE VIEW week07_lab.hw76_new_robots AS SELECT id,name FROM week07_lab.hw76_robots;
UPDATE week07_lab.hw76_old_robots SET full_name='Scout One Updated' WHERE id=1;
-- Views track the underlying column by dependency; the old view output name
-- remains full_name. Retire it only when no old client uses that contract.
SELECT a.id,a.full_name,b.name FROM week07_lab.hw76_old_robots a JOIN week07_lab.hw76_new_robots b USING(id);
-- END HW7.6

-- BEGIN HW7.7
CREATE TABLE week07_lab.hw77_events(event_at timestamp NOT NULL,event_id bigint GENERATED ALWAYS AS IDENTITY,robot_id integer NOT NULL,event_type text NOT NULL,PRIMARY KEY(event_at,event_id)) PARTITION BY RANGE(event_at);
CREATE TABLE week07_lab.hw77_events_sep PARTITION OF week07_lab.hw77_events FOR VALUES FROM('2026-09-01') TO('2026-10-01');
CREATE TABLE week07_lab.hw77_events_oct PARTITION OF week07_lab.hw77_events FOR VALUES FROM('2026-10-01') TO('2026-11-01');
INSERT INTO week07_lab.hw77_events(event_at,robot_id,event_type) VALUES('2026-09-30 23:59:59',1,'scan'),('2026-10-01',1,'scan');
DO $$ BEGIN BEGIN INSERT INTO week07_lab.hw77_events(event_at,robot_id,event_type) VALUES('2026-08-31 23:59:59',1,'scan');RAISE EXCEPTION 'Expected missing partition';EXCEPTION WHEN check_violation THEN NULL;END;END $$;
-- Parent uniqueness must include the partition key. Generated identity values
-- are convenient but do not declare a globally unique event_id constraint.
SELECT tableoid::regclass::text AS partition_name,count(*) AS events FROM week07_lab.hw77_events GROUP BY tableoid ORDER BY partition_name;
-- END HW7.7

-- BEGIN HW7.8
CREATE TABLE week07_lab.hw78_robots(id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,name text NOT NULL,access_code text NOT NULL DEFAULT(substr(md5(random()::text||clock_timestamp()::text),1,8)) UNIQUE CHECK(access_code ~ '^[0-9a-f]{8}$'));
INSERT INTO week07_lab.hw78_robots(name) SELECT 'Lab Robot '||n FROM generate_series(1,5) n;
DO $$ BEGIN BEGIN INSERT INTO week07_lab.hw78_robots(name,access_code) SELECT 'Duplicate',access_code FROM week07_lab.hw78_robots ORDER BY id LIMIT 1;RAISE EXCEPTION 'Expected duplicate code';EXCEPTION WHEN unique_violation THEN NULL;END;END $$;
-- A collision raises unique_violation; the application can retry generating
-- a code. These demonstration codes are identifiers, not security tokens.
SELECT id,name,access_code FROM week07_lab.hw78_robots ORDER BY id;
-- END HW7.8

-- BEGIN HW7.9
CREATE TABLE week07_lab.hw79_manufacturers(id integer PRIMARY KEY,name text NOT NULL);
CREATE TABLE week07_lab.hw79_models(id integer PRIMARY KEY,manufacturer_id integer NOT NULL,CONSTRAINT hw79_manufacturer_fk FOREIGN KEY(manufacturer_id) REFERENCES week07_lab.hw79_manufacturers(id) DEFERRABLE INITIALLY DEFERRED);
INSERT INTO week07_lab.hw79_models VALUES(100,1);
INSERT INTO week07_lab.hw79_manufacturers VALUES(1,'Astra Robotics');
SET CONSTRAINTS week07_lab.hw79_manufacturer_fk IMMEDIATE;
DO $$ BEGIN BEGIN INSERT INTO week07_lab.hw79_models VALUES(200,99);RAISE EXCEPTION 'Expected missing manufacturer';EXCEPTION WHEN foreign_key_violation THEN NULL;END;END $$;
-- Integrity remains enforced at the explicit check or transaction commit;
-- only its timing changes. This block requires the transaction in the setup note.
SELECT m.id,m.manufacturer_id,p.name FROM week07_lab.hw79_models m JOIN week07_lab.hw79_manufacturers p ON p.id=m.manufacturer_id;
-- END HW7.9

-- BEGIN HW7.10
CREATE TABLE week07_lab.hw710_missions AS SELECT * FROM public.missions;
CREATE INDEX hw710_operator_recent ON week07_lab.hw710_missions(operator_id,started_at DESC,id DESC) WHERE status='completed';
CREATE INDEX hw710_completed_costs ON week07_lab.hw710_missions(started_at) INCLUDE(cost) WHERE status='completed';
ANALYZE week07_lab.hw710_missions;
-- Equality on operator_id precedes the ordered lookup keys. The second index
-- supports time ranges and can supply cost from the index when visibility allows.
-- Partial predicates match completed-only queries. A small table may be cheaper
-- to scan sequentially; index creation alone does not guarantee index selection.
SELECT indexname,indexdef FROM pg_indexes WHERE schemaname='week07_lab' AND tablename='hw710_missions' ORDER BY indexname;
-- END HW7.10
