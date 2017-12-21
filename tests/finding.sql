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

raise notice 'Looking up one customer by term returns';
select * into res from dox.find_one(collection => 'customers', term =>'{"name":"chuck"}');

assert res ->> 'id' = '1';
assert res ->> 'name' = 'chuck';

raise notice 'Looking up customers by company returns 2';
select count(1) into found from dox.find(
  collection => 'customers', 
  term => '{"company":"red4"}'
);

assert found = 2, 'Bad find';

raise notice 'Looking up using fuzzy returns 2';
select count(1) into found from dox.fuzzy(
  collection => 'customers', 
  key => 'company',
  term => 'red'
);
assert found = 2, 'Bad fuzz';

raise notice 'Looking up using search returns 2';
select count(1) into found from dox.search(
  collection => 'customers', 
  term => 'red4'
);
assert found = 2, 'Bad search';

end;
$$ language plpgsql;


