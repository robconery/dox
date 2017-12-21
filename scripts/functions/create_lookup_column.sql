set search_path=dox;

drop function if exists create_lookup_column(varchar,varchar, varchar);
create function create_lookup_column(collection varchar, schema varchar, key varchar, out res bool)
as $$
declare
	column_exists int;
  lookup_key varchar := 'lookup_' || key;
begin
		execute format('SELECT count(1)
										FROM information_schema.columns
										WHERE table_name=%L and table_schema=%L and column_name=%L',
									collection,schema,lookup_key) into column_exists;

		if column_exists < 1 then
			-- add the column
			execute format('alter table %s.%s add column %s text', schema, collection, lookup_key);

			-- fill it
			execute format('update %s.%s set %s = body ->> %L', schema, collection, lookup_key, key);

			-- index it
			execute format('create index on %s.%s(%s)', schema, collection, lookup_key);

      -- TODO: drop a trigger on this!
      execute format('CREATE TRIGGER trigger_update_%s_%s
      AFTER UPDATE ON %s.%s
      FOR EACH ROW
      WHEN (OLD.body IS DISTINCT FROM new.body) 
      EXECUTE PROCEDURE dox.update_lookup();'
      ,collection, lookup_key, schema, collection);
		end if;
		res := true;
end;
$$ language plpgsql;
