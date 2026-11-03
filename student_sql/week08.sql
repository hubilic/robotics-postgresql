-- Same-schema PostgreSQL exercises. See the corresponding PDF.

-- IC8.1 -- A mission review list with guest operators
select
	m.id as mission_id,
	o.name as operator_name,
	o.country,
	m.cost
from missions m left join operators o on m.operator_id = o.id
where m.started_at >= timestamp '2026-09-01' and m.started_at < timestamp '2026-10-01'
and (m.status is null or m.status ='queued')
order by  m.id;

-- IC8.2 -- Historical deployment rates versus current rates
select
	mi.id,
	rm.name,
	ma.name,
	mr.robot_count,
	mr.robot_count * mr.unit_cost as historical_deployment,
	mr.unit_cost,
	rm.unit_cost
from missions mi join mission_robots mr on mi.id = mr.mission_id
join robot_models rm on mr.robot_model_id = rm.id
join manufacturers ma on rm.manufacturer_id = ma.id
where mi.started_at >= timestamp '2026-09-01' and mi.started_at < timestamp '2026-10-01'
and mr.unit_cost <> rm.unit_cost 
order by mi.id, rm.id;

-- IC8.3 -- Operators without a September completion
-- Your SQL:


-- IC8.4 -- Two levels of robot category ancestry
-- Your SQL:


-- IC8.5 -- The first fourteen days of operator activity
-- Your SQL:


-- IC8.6 -- Fleet availability changes with unknown counts
-- Your SQL:


-- IC8.7 -- An operator calendar from registration onward
-- Your SQL:


-- IC8.8 -- The latest completed mission per operator
-- Your SQL:


-- IC8.9 -- Technical document labels without missing documents
-- Your SQL:


-- IC8.10 -- Manufacturer deployment totals at the right grain
-- Your SQL:


-- HW8.1 -- A four-state operator mission profile
-- Your SQL:


-- HW8.2 -- Possible duplicate operator identities
-- Your SQL:


-- HW8.3 -- The previous completed mission in a stable history
-- Your SQL:


-- HW8.4 -- Tags absent from September robot documentation
-- Your SQL:


-- HW8.5 -- Distinct operators deploying each manufacturer's robots
-- Your SQL:


-- HW8.6 -- Operators two collaboration links away
-- Your SQL:


-- HW8.7 -- Inspections without prior completed deployment
-- Your SQL:


-- HW8.8 -- Two missions for planned-cost review per operator
-- Your SQL:


-- HW8.9 -- Robot model suggestions from direct partners
-- Your SQL:


-- HW8.10 -- Related technical documents using Jaccard similarity
-- Your SQL:

