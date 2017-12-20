set search_path=dox;
drop function if exists search(varchar, varchar, varchar);
create function search(collection varchar, term varchar, schema varchar default 'public')
returns setof jsonb
as $$
declare
begin
	return query
	execute format('select body 
									from %s.%s 
									where search @@ plainto_tsquery(''"%s"'')
									order by ts_rank_cd(search,plainto_tsquery(''"%s"'')) desc'
			,schema,collection,term, term);
end;
	
$$ language plpgsql;