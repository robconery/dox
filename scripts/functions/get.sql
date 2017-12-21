set search_path=dox;
drop function if exists get(varchar,int,varchar);
create function get(collection varchar, id int, schema varchar default 'public', out res jsonb)
as $$
	
begin
		execute format('select body from %s.%s where id=%s',schema,collection, id) into res;
end;

$$ language plpgsql;