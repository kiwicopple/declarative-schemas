-- Alters `template1`. 
-- We might need to set up a new template for supabase (called `template_supabase`) so that
--  we don't mess with defaults. Unfortunately I couldn't get this to work because tusker or migra kept
-- using `template1` instead of `template_supabase` when comparing the databases.


create schema if not exists auth;
create schema if not exists  extensions;
create schema if not exists  storage;
create extension if not exists "uuid-ossp"      with schema extensions;
create extension if not exists pgcrypto         with schema extensions;


create table if not exists 
  auth.users (
    instance_id uuid null,
    id uuid not null,
    aud character varying(255) null,
    role character varying(255) null,
    email character varying(255) null,
    encrypted_password character varying(255) null,
    email_confirmed_at timestamp with time zone null,
    invited_at timestamp with time zone null,
    confirmation_token character varying(255) null,
    confirmation_sent_at timestamp with time zone null,
    recovery_token character varying(255) null,
    recovery_sent_at timestamp with time zone null,
    email_change_token_new character varying(255) null,
    email_change character varying(255) null,
    email_change_sent_at timestamp with time zone null,
    last_sign_in_at timestamp with time zone null,
    raw_app_meta_data jsonb null,
    raw_user_meta_data jsonb null,
    is_super_admin boolean null,
    created_at timestamp with time zone null,
    updated_at timestamp with time zone null,
    phone text null default null::character varying,
    phone_confirmed_at timestamp with time zone null,
    phone_change text null default ''::character varying,
    phone_change_token character varying(255) null default ''::character varying,
    phone_change_sent_at timestamp with time zone null,
    confirmed_at timestamp with time zone null,
    email_change_token_current character varying(255) null default ''::character varying,
    email_change_confirm_status smallint null default 0,
    banned_until timestamp with time zone null,
    reauthentication_token character varying(255) null default ''::character varying,
    reauthentication_sent_at timestamp with time zone null,
    is_sso_user boolean not null default false,
    deleted_at timestamp with time zone null,
    constraint users_pkey primary key (id),
    constraint users_phone_key unique (phone),
    constraint users_email_change_confirm_status_check check (
      (
        (email_change_confirm_status >= 0)
        and (email_change_confirm_status <= 2)
      )
    )
  );


create or replace function auth.uid() 
returns uuid 
language sql stable
as $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;

create or replace function auth.role() 
returns text 
language sql stable
as $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;

create or replace function auth.email() 
returns text 
language sql stable
as $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


CREATE TABLE if not exists  "storage"."buckets" (
    "id" text not NULL,
    "name" text NOT NULL,
    "owner" uuid,
    "created_at" timestamptz DEFAULT now(),
    "updated_at" timestamptz DEFAULT now(),
    CONSTRAINT "buckets_owner_fkey" FOREIGN KEY ("owner") REFERENCES "auth"."users"("id"),
    PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "bname" ON "storage"."buckets" USING BTREE ("name");

CREATE TABLE if not exists  "storage"."objects" (
    "id" uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    "bucket_id" text,
    "name" text,
    "owner" uuid,
    "created_at" timestamptz DEFAULT now(),
    "updated_at" timestamptz DEFAULT now(),
    "last_accessed_at" timestamptz DEFAULT now(),
    "metadata" jsonb,
    CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets"("id"),
    CONSTRAINT "objects_owner_fkey" FOREIGN KEY ("owner") REFERENCES "auth"."users"("id"),
    PRIMARY KEY ("id")
);

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION storage.foldername(name text)
 RETURNS text[]
 LANGUAGE plpgsql
AS $function$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[1:array_length(_parts,1)-1];
END
$function$;

CREATE OR REPLACE FUNCTION storage.filename(name text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$function$;

CREATE OR REPLACE FUNCTION storage.extension(name text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
_parts text[];
_filename text;
BEGIN
	select string_to_array(name, '/') into _parts;
	select _parts[array_length(_parts,1)] into _filename;
	-- @todo return the last part instead of 2
	return reverse(split_part(reverse(_filename), '.', 1));
END
$function$;

-- @todo can this query be optimised further?
CREATE OR REPLACE FUNCTION storage.search(prefix text, bucketname text, limits int DEFAULT 100, levels int DEFAULT 1, offsets int DEFAULT 0)
 RETURNS TABLE (
    name text,
    id uuid,
    updated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    last_accessed_at TIMESTAMPTZ,
    metadata jsonb
  )
 LANGUAGE plpgsql
AS $function$
BEGIN
	return query 
		with files_folders as (
			select ((string_to_array(objects.name, '/'))[levels]) as folder
			from objects
			where objects.name ilike prefix || '%'
			and bucket_id = bucketname
			GROUP by folder
			limit limits
			offset offsets
		) 
		select files_folders.folder as name, objects.id, objects.updated_at, objects.created_at, objects.last_accessed_at, objects.metadata from files_folders 
		left join objects
		on prefix || files_folders.folder = objects.name and objects.bucket_id=bucketname;
END
$function$;