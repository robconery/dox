set search_path=dox;

drop function if exists update_lookup();
create function update_lookup()
returns trigger 
as $$
declare
  lookup_key text;
	json_key text;
begin
	
	for lookup_key in (select column_name from information_schema.columns
										where table_name=TG_TABLE_NAME and table_schema=TG_TABLE_SCHEMA 
										and column_name like 'lookup_%')
	loop 
		json_key := split_part(lookup_key,'_',2);

    execute format('update %s.%s set %s = %L where id=%s',
                    TG_TABLE_SCHEMA, 
                    TG_TABLE_NAME, 
                    lookup_key, new.body ->> json_key, 
                    new.id
                  );
  end loop;
  return new;
end;
$$ language plpgsql;
