set client_min_messages TO WARNING;
drop schema if exists dox cascade;
create schema if not exists dox;
set search_path=dox;
drop function if exists create_collection(varchar,varchar,varchar,bool);
create function create_collection(
	collection varchar, 
	indexed varchar default null, 
	schema varchar default 'dox', 
	force bool default false,
	out res jsonb
)
as $$
declare
	table_sql varchar;
begin
	res := '{"created": false, "message": null}';
	-- see if table exists first
  if not exists (select 1 from information_schema.tables where table_schema = schema AND table_name = collection) then
    
    if force then 
      execute format('drop table if exists %s.%s cascade',schema,collection);
    end if;

    execute format('create table %s.%s(
            id serial primary key not null,
            body jsonb not null,
            search tsvector,
            created_at timestamptz not null default now(),
            updated_at timestamptz not null default now()
          );',schema,collection);

    execute format('create index idx_search_%s on %s.%s using GIN(search)',collection,schema,collection);
    -- index?
    if(indexed is null) then
      execute format('create index idx_json_%s on %s.%s using GIN(body jsonb_path_ops)',collection,schema,collection);
    else
      execute format('create index idx_json_%s on %s.%s using GIN((body -> %L))',collection,schema,collection, indexed);
    end if;
    res := '{"created": true, "message": "Table created"}';
  else
    res := '{"created": false, "message": "Table exists"}';		
    raise debug 'This table already exists';

  end if;

end;
$$
language plpgsql;set search_path=dox;
drop function if exists create_lookup_column(varchar,varchar, varchar);
create function create_lookup_column(collection varchar, schema varchar, key varchar, out res bool)
as $$
declare
	column_exists int;
begin
		execute format('SELECT count(1)
										FROM information_schema.columns
										WHERE table_name=%L and table_schema=%L and column_name=%L',
									collection,schema,'lookup_' || key) into column_exists;

		if column_exists < 1 then
			-- add the column
			execute format('alter table %s.%s add column %s text', schema, collection, 'lookup_' || key);

			-- fill it
			execute format('update %s.%s set %s = body ->> %L', schema, collection, 'lookup_' || key, key);

			-- index it
			execute format('create index on %s.%s(%s)', schema, collection, 'lookup_' || key);

      -- TODO: drop a trigger on this!

		end if;
		res := true;
end;
$$ language plpgsql;
set search_path=dox;
drop function if exists create_collection(varchar,varchar,varchar,bool);
create function create_collection(
	collection varchar, 
	indexed varchar default null, 
	schema varchar default 'dox', 
	force bool default false,
	out res jsonb
)
as $$
declare
	table_sql varchar;
begin
	res := '{"created": false, "message": null}';
	-- see if table exists first
		if not exists (select 1 from information_schema.tables where table_schema = schema AND table_name = collection) then
			
			if force then 
				execute format('drop table if exists %s.%s cascade',schema,collection);
			end if;

			execute format('create table %s.%s(
							id serial primary key not null,
							body jsonb not null,
							search tsvector,
							created_at timestamptz not null default now(),
							updated_at timestamptz not null default now()
						);',schema,collection);

			execute format('create index idx_search_%s on %s.%s using GIN(search)',collection,schema,collection);
			-- index?
			if(indexed is null) then
				execute format('create index idx_json_%s on %s.%s using GIN(body jsonb_path_ops)',collection,schema,collection);
			else
				execute format('create index idx_json_%s on %s.%s using GIN((body -> %L))',collection,schema,collection, indexed);
			end if;
			res := '{"created": true, "message": "Table created"}';
		else
			res := '{"created": false, "message": "Table exists"}';		
			raise debug 'This table already exists';

		end if;

end;
$$
language plpgsql;

set search_path=dox;
drop function if exists drop_lookup_columns(varchar, varchar);
create function drop_lookup_columns(
	collection varchar,
	schema varchar default 'public',
	out res bool
)
as $$
declare lookup text;
begin
		for lookup in execute format('SELECT column_name
										FROM information_schema.columns
										WHERE table_name=%L AND table_schema=%L AND column_name LIKE %L',
									collection,schema,'lookup%') loop
			execute format('alter table %s.%s drop column %I', schema, collection, lookup);
		end loop;

		res := true;
end;
$$ language plpgsql;
set search_path=dox;
drop function if exists ends_with(varchar, varchar, varchar, varchar);
create function ends_with(
	collection varchar,
	key varchar,
	term varchar,
	schema varchar default 'public'
)
returns setof jsonb
as $$
declare
	search_param text := '%' || term;
begin

	-- ensure we have the lookup column created if it doesn't already exist
	perform dox.create_lookup_column(collection => collection, schema => schema, key => key);

	return query
	execute format('select body from %s.%s where %s ilike %L',schema,collection,'lookup_' || key,search_param);
end;
$$ language plpgsql;
set search_path=dox;
drop function if exists "exists"(varchar, text,varchar);
create function "exists"(
	collection varchar, 
	term text,
	schema varchar default 'public'
)
returns setof jsonb
as $$
declare
	existence bool := false;
begin
	return query
	execute format('
		select body from %s.%s 
		where body ? %L;
',schema,collection, term);

end;
$$ language plpgsql;set search_path=dox;
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
set search_path=dox;
drop function if exists find_one(varchar, jsonb,varchar);
create function find_one(
	collection varchar, 
	term jsonb,
	schema varchar default 'public', 
	out res jsonb
)
as $$
begin

	execute format('
		select body from %s.%s 
		where body @> %L limit 1;
',schema,collection, term) into res;

end;
$$ language plpgsql;set search_path=dox;
drop function if exists fuzzy(varchar, varchar, varchar,varchar);
create function fuzzy(
	collection varchar, 
	key varchar,
	term varchar,
	schema varchar default 'public' 
)
returns setof jsonb
as $$
begin
	return query
	execute format('
	select body from %s.%s 
	where body ->> %L ~* %L;
',schema,collection, key, term);

end;
$$ language plpgsql;set search_path=dox;
drop function if exists get(varchar,int,varchar);
create function get(collection varchar, id int, schema varchar default 'public', out res jsonb)
as $$
	
begin
		execute format('select body from %s.%s where id=%s',schema,collection, id) into res;
end;

$$ language plpgsql;set search_path=dox;
drop function if exists modify(varchar, int, jsonb, varchar);
create function modify(
	collection varchar, 
	id int,
	set jsonb,
	schema varchar default 'public',
	out res jsonb
)
as $$

begin
	-- join it
	execute format('select body || %L from %s.%s where id=%s', set,schema,collection, id) into res;

	-- save it - this will also update the search
	perform dox.save(collection => collection, schema => schema, doc => res);
end;

$$ language plpgsql;set search_path=dox;
drop function if exists save(varchar, jsonb,text[],varchar);
create function save(
	collection varchar, 
	doc jsonb, 
	search text[] = array['name','email','first','first_name','last','last_name','description','title','city','state','address','street', 'company'],
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
	

	-- make sure the table exists
	perform dox.create_collection(collection => collection, schema => schema);
	

	if (select doc ? 'id') then

		execute format('insert into %s.%s (id, body) 
										values (%L, %L) 
										on conflict (id)
										do update set body = excluded.body, updated_at = now()
										returning *',schema,collection, doc -> 'id', doc) into saved;
	
	else
		-- there's no document id
		execute format('insert into %s.%s (body) values (%L) returning *',schema,collection, doc) into saved;

		-- this will have an id on it
		
		select(doc || format('{"id": %s}', saved.id::text)::jsonb) into res;
		execute format('update %s.%s set body=%L, updated_at = now() where id=%s',schema,collection,res,saved.id);
		

	end if;
	res := saved.body;
	-- do it automatically MMMMMKKK?
	foreach search_key in array search
	loop
		if(res ? search_key) then
			search_params :=  concat(search_params,' ',res ->> search_key);
		end if;
	end loop;
	if search_params is not null then
		execute format('update %s.%s set search=to_tsvector(%L) where id=%s',schema,collection,search_params,saved.id);
	end if;

end;

$$ language plpgsql;set search_path=dox;
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
	
$$ language plpgsql;set search_path=dox;
drop function if exists starts_with(varchar, varchar, varchar, varchar);
create function starts_with(
	collection varchar,
	key varchar,
	term varchar,
	schema varchar default 'public'
)
returns setof jsonb
as $$
declare
	search_param text := term || '%';
begin

	-- ensure we have the lookup column created if it doesn't already exist
	perform dox.create_lookup_column(collection => collection, schema => schema, key => key);

	return query
	execute format('select body from %s.%s where %s ilike %L',schema,collection,'lookup_' || key,search_param);
end;
$$ language plpgsql;
