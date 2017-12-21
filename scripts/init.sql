drop schema if exists dox;
create schema dox;

-- set the defaults here
drop table if exists dox._opts;
create table dox._opts(
	id serial primary key,
	search_args text[]
);

insert into dox._opts(search_args)
values(array['name','email','first','first_name','last','last_name','description','title','city','state','address','street']);
