-- IC6.1 -- Operators with recent completed missions
select o.id, o.name, o.country
from operators o
where o.deleted_at is null
and o.id in (
	select m.operator_id 
	from missions m 
	where m.status = 'completed'
	and m.started_at >= '2026-09-01' 
	and m.started_at < '2026-10-01'
)
order by o.id;

-- IC6.2 -- Five missions for planned-cost review
select m.id, m.cost,
	(
	select o.name
	from operators o
	where o.id = m.operator_id 
	) as operator_name
from missions m
where m.started_at < '2026-10-01' 
and (m.status = 'queued' or m.status is null)
and m.cost >= '100'
order by m.cost desc, m.id asc 
limit 5;

-- IC6.3 -- Operator contact availability
select
	o.id,
	o.email,
	case
		when o.email is null then 'null_email'
		when trim(o.email) = '' then 'blank_email'
		else 'available'
	end as contact_state
from operators o 
order by 
	case
		when o.email is null then 1
		when trim(o.email) = '' then 2
		else 3
	end,
	o.id


-- IC6.4 -- Country coverage for a robot training session
select 
	o.id,
	o.name,
	o.country 
from operators o 
where o.country = 'PL'
or o.country is null
order by 
	case
		when o.country = 'PL' then 1
		else 2
	end,
	o.id;
	 

-- IC6.5 -- Literal characters in robot model names
select 
	rm.id,
	rm.name,
	rm.unit_cost
from robot_models rm 
where rm."name" like '%!_%' escape '!'
or rm."name" like '%!%%' escape '!'
order by id;


-- IC6.6 -- Prioritize the mission review list
select
	m.id,
	m.status,
	m.started_at,
	m.cost
from missions m 
where m.started_at < '2026-10-01'
order by 
	case
		when m.status = 'queued' then 1
		when m.status is null then 2
		when m.status = 'completed' then 3
		when m.status = 'aborted' then 4
		else 5
	end,
	m.started_at asc nulls last,
	m.cost desc nulls last,
	m.id asc;

-- IC6.7 -- Age of completed mission records
select
	m.id,
	m.started_at,
	timestamp '2026-10-01' - m.started_at as age_days
from missions m 
where timestamp '2026-10-01' - m.started_at < interval '60 days'
order by m.started_at, m.id;


-- IC6.8 -- Registration to first completed mission
-- Your SQL:


-- IC6.9 -- Mission history without an abort
-- Your SQL:


-- IC6.10 -- Mission costs above an operator's baseline
-- Your SQL:


-- HW6.1 -- Explain operator email-quality issues
-- Your SQL:


-- HW6.2 -- The second mission-cost tier by country
-- Your SQL:


-- HW6.3 -- An operator experience lifecycle
-- Your SQL:


-- HW6.4 -- Mask operator contact details
-- Your SQL:


-- HW6.5 -- A mission's share of completed costs
-- Your SQL:


-- HW6.6 -- Robot models without a completed deployment
-- Your SQL:


-- HW6.7 -- Operators with a high abort share
-- Your SQL:


-- HW6.8 -- Completed-mission cost ranges
-- Your SQL:


-- HW6.9 -- Gaps in completed-mission activity
-- Your SQL:


-- HW6.10 -- A seven-day operator activation report
-- Your SQL:

