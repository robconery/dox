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