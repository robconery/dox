DO $$
declare
  res jsonb;
  found int;
begin

set client_min_messages=NOTICE;
raise notice '******************** Modify ********************';

raise notice 'Altering an email address updates record';
select * into res from dox.modify(
  id => 1,
  collection => 'customers', 
  set => '{"name": "harold"}'
);

assert res ->> 'name' = 'harold', 'Not modifed';

raise notice 'It also updates the lookup';
select count(1) into found
from customers where lookup_name = 'harold';

end;
$$ language plpgsql;