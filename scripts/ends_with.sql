set search_path=dox;
drop function if exists ends_with(varchar, varchar, varchar, varchar, bool);
create function ends_with(
	collection varchar, 
	key varchar, 
	term varchar, 
	schema varchar default 'public', 
	migrate bool default false
)
returns setof jsonb
as $$
declare
	search_param text := '%' || term;
begin
	
	-- is there a column with this name?
	if migrate then
		perform dox.create_lookup_column(collection => collection, schema => schema, key => key);
	end if;

	return query 
	execute format('select body from %s.%s where %s ilike %L',schema,collection,key,search_param);
end;
$$ language plpgsql;