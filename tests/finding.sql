DO $$
declare
  res jsonb;
begin

--drop customers
raise notice 'dropping customers';
drop table if exists customers;
set client_min_messages=NOTICE;
raise notice 'Save works for basic operation and creates a table';
select * into res from dox.save(
  collection => 'customers', 
  doc => '{"name": "chuck", "email:":"chuck@test.com"}'
);

assert (res ->> 'name') = 'chuck', 'Nope, bad save';
assert (res ->> 'id') = '1', 'Nope, bad save';

raise notice 'Save will create a second customer';
select * into res from dox.save(
  collection => 'customers', 
  doc => '{"name": "julie", "email:":"jux@test.com"}'
);

assert (res ->> 'name') = 'julie', 'Nope, bad save';
assert (res ->> 'id') = '2', 'Nope, bad save';

end;
$$ language plpgsql;


