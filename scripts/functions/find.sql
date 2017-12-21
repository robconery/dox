set search_path=dox;
drop function if exists find(varchar, jsonb,varchar);
create function find(
	collection varchar, 
	term jsonb,
	schema varchar default 'public' 
)
returns setof jsonb
as $$
begin
	return query
	execute format('
		select body from %s.%s 
		where body @> %L;
',schema,collection, term);

end;
$$ language plpgsql;
