SET search_path TO "public";

create function hello_world() 
returns text 
language sql
as 
$$
  select 'Hello world';
$$;

