DO $$
declare
  res jsonb;
  found int;
begin

set client_min_messages=NOTICE;
raise notice '******************** FINDING THINGS ********************';

raise notice 'Looking up customers by id returns';
select * into res from dox.get(collection => 'customers', id => 1);

assert res ->> 'id' = '1';
assert res ->> 'name' = 'chuck';


raise notice 'Looking up customers by id returns';
select * into res from dox.get(collection => 'customers', id => 1);

assert res ->> 'id' = '1';
assert res ->> 'name' = 'chuck';

raise notice 'Looking up customers by company returns 2';
select count(1) into found from dox.find(
  collection => 'customers', 
  term => '{"company":"red4"}'
);

assert found = 2, 'Bad find';

end;
$$ language plpgsql;


