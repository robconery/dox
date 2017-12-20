set search_path=dox;
drop function if exists starts_with(varchar, varchar, varchar, varchar, bool);
create function starts_with(
collection varchar, 
key varchar, 
term varchar, 
schema varchar default 'public', 
migrate bool default false
)
returns setof jsonb
as $$
declare
	check_query text;
	column_exists int;
	search_param text := term || '%';
	search_query text := format('select body from %s.%s where %s ilike %L',schema,collection,key,search_param);
begin
	
	-- is there a column with this name?
	execute format('SELECT count(1) 
											FROM information_schema.columns 
											WHERE table_name=%L and table_schema=%L and column_name=%L',
										collection,schema,key) into column_exists;
	
	if column_exists > 0 then
		return query execute search_query;
	elseif migrate then
		-- add the column
		execute format('alter table %s.%s add column %s text', schema, collection,key);
		-- fill it
		execute format('update %s.%s set %s = body ->> %L', schema, collection, key, key);

		-- index it
		execute format('create index on %s.%s(%s)', schema,collection,key);
		return query execute search_query;
	end if;


end;
$$ language plpgsql;