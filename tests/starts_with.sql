DO $$
declare
  res jsonb;
  found int;
begin

set client_min_messages=NOTICE;
raise notice '******************** Using starts_with ********************';

raise notice 'Looking up customers by id returns';
select count(1) into found from dox.starts_with(
  collection => 'customers', 
  key => 'name',
  term => 'c'
);

raise notice '... and creates a column';
select count(1) into found from information_schema.columns
where table_name='customers' and table_schema='public' and column_name='name';

assert found = 1, 'No column added';

end;
$$ language plpgsql;