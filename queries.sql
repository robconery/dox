delete from store.films;
select film_id, row_to_json(film),
	dox.save(collection => 'films',schema => 'store', doc => row_to_json(film)::jsonb)
from film;