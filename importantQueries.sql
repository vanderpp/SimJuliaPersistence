with tbl as (
	SELECT 	modelname, 
			max(lastused) as lused 
	FROM 	public.modelmetadata 
	group by modelname
)
select 	'ProbeResult'||m.modelname||m.modelhashcode as objectclassname
from 	modelmetadata m inner join tbl t on 	m.modelname = t.modelname and
												m.lastused = t.lused