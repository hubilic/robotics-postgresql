-- Run after 01_setup.sql. Read-only assertions.
DO $$ BEGIN
 IF(SELECT count(*) FROM public.operators)<>24 THEN RAISE EXCEPTION 'Wrong operators count';END IF;
 IF(SELECT count(*) FROM public.missions)<>210 THEN RAISE EXCEPTION 'Wrong missions count';END IF;
 IF(SELECT count(*) FROM public.manufacturers)<>6 THEN RAISE EXCEPTION 'Wrong manufacturers count';END IF;
 IF(SELECT count(*) FROM public.robot_categories)<>9 THEN RAISE EXCEPTION 'Wrong robot_categories count';END IF;
 IF(SELECT count(*) FROM public.robot_models)<>12 THEN RAISE EXCEPTION 'Wrong robot_models count';END IF;
 IF(SELECT count(*) FROM public.mission_robots)<>279 THEN RAISE EXCEPTION 'Wrong mission_robots count';END IF;
 IF(SELECT count(*) FROM public.inspections)<>27 THEN RAISE EXCEPTION 'Wrong inspections count';END IF;
 IF(SELECT count(*) FROM public.robot_inventory_morning)<>9 THEN RAISE EXCEPTION 'Wrong robot_inventory_morning count';END IF;
 IF(SELECT count(*) FROM public.robot_inventory_evening)<>9 THEN RAISE EXCEPTION 'Wrong robot_inventory_evening count';END IF;
 IF(SELECT count(*) FROM public.technical_documents)<>12 THEN RAISE EXCEPTION 'Wrong technical_documents count';END IF;
 IF(SELECT count(*) FROM public.tags)<>8 THEN RAISE EXCEPTION 'Wrong tags count';END IF;
 IF(SELECT count(*) FROM public.document_tags)<>24 THEN RAISE EXCEPTION 'Wrong document_tags count';END IF;
 IF(SELECT count(*) FROM public.operator_links)<>24 THEN RAISE EXCEPTION 'Wrong operator_links count';END IF;
 IF(SELECT count(*) FROM public.robot_metrics)<>16 THEN RAISE EXCEPTION 'Wrong robot_metrics count';END IF;
 IF(SELECT count(*) FROM public.sensor_readings)<>5 THEN RAISE EXCEPTION 'Wrong sensor_readings count';END IF;
 IF EXISTS(SELECT 1 FROM public.missions m LEFT JOIN(SELECT mission_id,sum(robot_count*unit_cost) AS c FROM public.mission_robots GROUP BY mission_id) l ON l.mission_id=m.id WHERE m.cost IS DISTINCT FROM l.c) THEN RAISE EXCEPTION 'Mission cost mismatch';END IF;
 IF EXISTS(SELECT 1 FROM public.missions WHERE started_at>=timestamp '2026-10-01') THEN RAISE EXCEPTION 'Future mission';END IF;
END $$;
SELECT 'Robotics setup checks passed' AS result;
