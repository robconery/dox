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

These queries will be performant as they will be able to flex indexing, but there's a lot more you can do if you like using plain old SQL clauses:

```sql
select * from dox.fuzzy(collection => 'customers', key => 'company', term => 'Red');
select * from dox.starts_with(collection => 'customers', key => 'company', term => 'Red');
select * from dox.ends_with(collection => 'customers', key => 'company', term => '4);
```

These queries will, unfortunately, use a sequential scan (they have to). But there are ways around this! One of my plans is to include the ability to use traditional columns and values to locate data from a document. I'm still musing on this, but I have a few ideas.

Lots more to come...


