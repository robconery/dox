DO $$
declare
  res jsonb;
begin

--drop customers
raise notice '******************** FINDING THINGS ********************';

raise notice 'Looking up customers by id returns';
select * into res from dox.get(collection => 'customers', id => 1);

assert res ->> 'id' = '1';

end;
$$ language plpgsql;


