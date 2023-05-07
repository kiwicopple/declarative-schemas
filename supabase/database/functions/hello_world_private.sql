SET search_path TO "private";

create function hello_world() 
returns text 
language sql
as 
$$
  select 'Hello world';
$$;

