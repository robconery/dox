set search_path=dox;
drop function if exists save(varchar, jsonb,text[],varchar);
create function save(
	name varchar, 
	doc jsonb, 
	search text[] = null,
	schema varchar default 'public', 
	out res jsonb
)
as $$

declare
	doc_id int := doc -> 'id';
	saved record;
	saved_doc jsonb;
	search_key varchar;
	search_params varchar;
begin
	
	if array_length(search,1) <= 0  or search is null then
		--get the first
		select search_args into search from dox._opts order by id limit 1;
	end if;

	-- make sure the table exists
	perform dox.create_table(name => name, schema => schema);
	

	if not (doc -> 'id') is null then

		execute format('insert into %s.%s (id, body) 
										values (%L, %L) 
										on conflict (id)
										do update set body = excluded.body, updated_at = now()
										returning body',schema,name, doc -> 'id', doc);
		res := new_doc;
	
	else
		execute format('insert into %s.%s (body) values (%L) returning *',schema,name, doc) into saved;

		-- this will have an id on it
		
		select(doc || format('{"id": %s}', saved.id::text)::jsonb) into res;
		execute format('update %s.%s set body=%L, updated_at = now() where id=%s',schema,name,res,saved.id);
		
		--res:= saved_doc;
	end if;

	-- do it automatically MMMMMKKK?
	foreach search_key in array search
	loop
		if(res ? search_key) then
			search_params :=  concat(search_params,' ',res ->> search_key);
		end if;
	end loop;
	if search_params is not null then
		execute format('update %s.%s set search=to_tsvector(%L) where id=%s',schema,name,search_params,saved.id);
	end if;

end;

$$ language plpgsql;