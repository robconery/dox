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
