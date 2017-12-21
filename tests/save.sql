set client_min_messages=NOTICE;
DO $$
declare
  res jsonb;
begin

--drop customers
raise notice 'dropping customers';
drop table if exists customers;

raise notice 'a basic save of customers';
select * into res from dox.save(
  collection => 'customers', 
  doc => '{"name": "chuck", "email:":"chuck@test.com"}'
);
raise notice 'what is res? %', res::text;
assert (res ->> 'name') = 'chuck', 'Nope, bad save';

end;
$$ language plpgsql;


