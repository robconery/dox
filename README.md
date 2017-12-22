# A Postgres Document API

Postgres has an amazing JSON document storage capability, the only problem is that working with it is a bit clunky. Thus, I'm creating a set of extensions that, hopefully, will offer a basic API.


## Quick Example

Let's say you have a JSON document called `customer`:

```js
{
  name: "Jill",
  email: "jill@test.com",
  company: "Red:4"
}
```

You want to save this to Postgres using document storage as you know things will change. With this API you can do that by calling a simple function:

```sql
select * from dox.save(table => 'customers', doc => '[wad of json]');
```

This will do a few things:

 - A table named `customers` will be created with a single JSONB field, dates, an ID and a `tsvector` search field.
 - The `id` that's created will be appended to the new document, and returned from this call
 - A search index is automatically created using conventional key names, which you can configure. In this case it will recognize `email` and `name` as something that needs indexing.
 - The entire document will be indexed using `GIN` indexing, which again, is configurable.
 - The search index will be indexed using `GIN` as well, for speed.

Now, you can query your document thus:

```sql
select * from dox.search(collection => 'customers', term => 'jill'); -- full text search on a single term
select * from dox.find_one(collection => 'customers', term => '{"name": "Jill"}'); -- simple query
select * from dox.find(collection => 'customers', term => '{"company": "Red:4"}'); -- find all Red:4 people
```

These queries will be performant as they will be able to flex indexing, but there's a lot more you can do.

## Fuzzy Queries, Starts and Ends With

One of the downsides of using JSONB with Postgres is *finding things*. If you do any kind of loose querying on text, you end up doing a query like this:

```sql
select json from json_table
where json ->> 'email' ilike '.com%';
```

This query blows because it can't use an index. What's worse is that Postgres has to materialize the JSON to check the condition. The good news? *It's still faster than MongoDB* :).

There are ways to get around this, such as creating a new column simply for lookups on common keys. That way you could:

```sql
select json from json_table
where lookup_email ilike '.com%';
```

This is OK as there's an index on `lookup_email` that you added. Nice and fast! Doing this for every table is a pain, and how do you manage changes to the underlying data? A trigger! OH HEAVENS!

If you use `dox.starts_with` or `dox.ends_with` all of that is done for you. I should note that **this is not something you run in production**. This is something that you run locally as you're developing, and then have your change management script move the updates live. The problem is that if you use this on a very large table the update will take a while and the index creation will lock everything as you can't run `concurrently` from a function.

Anyway, it's there if you want it.

You can also do things the sequential table scan way (aka "bad") if you have a small table. For that you can use `dox.fuzzy`:

```sql
select * from dox.fuzzy(collection => 'customers', key => 'company', term => 'Red');
select * from dox.starts_with(collection => 'customers', key => 'company', term => 'Red');
select * from dox.ends_with(collection => 'customers', key => 'company', term => '4);
```

## Modification

Partial updates are also a pain with Postgres and JSONB although, yes, there is a way to do it better in 9.6+. All of that is wrapped up `dox.modify`:

```sql
select * into res from dox.modify(
  id => 1,
  collection => 'customers', 
  set => '{"name": "harold"}'
);
```

You can also just save things directly using `dox.save`.

## Installation

The simplest thing to do is to run `make` and you'll see a `build.sql` file in your home directory. You can run that against your database and off you go. It's just a set of functions placed within a schema to keep things clean.

You can also run `make install` if you change the name of the `DB` at the top of the file.

## Running The Tests

I wrote some tests using plain old SQL which you can run if you want. Just clone the repo and run `make test`, which will create a database for the tests on your local Postgres (assuming you have ownership of it).


