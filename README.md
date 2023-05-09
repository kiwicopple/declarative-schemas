# Declarative Schemas (POC)

A proof of concept for declarative schemas.

### Pre-reqs

- supabase cli
- [tusker](https://github.com/kiwicopple/tusker): `pip install git+https://github.com/kiwicopple/tusker.git@supabase`
  - use virtualenv: `pip install virtualenv`
    - `source venv/bin/activate`
    - `pip install -r requirements.txt`
    - [`deactivate` when finished]


### Getting started

- Start supabase by running `supabase start`
- run `make init.template` - this will update the `template1` template with relevant Supabase code (like `auth.uid()`). This is a bit of a hack, something that can be improved later.
- make some changes to the schema in `/supabase/database`

Migration management:

- `make db.changes` (could be `supabase db changes`)
  - if there are no changes then there will be no output. This can be improved by showing some actual output
- `make db.commit` (could be `supabase db commit`)
  - commit the files from the declarative structure into a migration
  - I think by default this should run on the local database. We could add a flag so that it just copies to the file system
- `supabase db reset`: pick up all the changes

Creating files:

- I think we should have a command `supabase db new` which gives a "wizard" experience. For now I have:
  - New schema: `make db.new.schema <schema_name>`
    - creates a new schema file and stores the "create" command in _init.sql
    - Prepends the schema search path at the top of the file
  - New Function: [NOT YET IMPLEMENTED]
    - we should ask the user which schema they want the function to be created in, then run a check to ensure that the schema exists. Add the search path at the top of the file.

### Fork?

I think we might be better off forking Tusker and running it ourselves while we're developing this

- we need to make migra/tusker compare to a template that is _not_ template1. At the moment I am modifying the `template1` database with relevant supabase DDL. A more sustainable way to do this will be to create a `template_supbase` template which we can run comparisons against.
- I had a lot of python warnings/issues running this - incompatibilities between versions and also mac M1 issues
- The codebase is small enough that it might be easier to replicate it into the CLI as code
- This provides filesystem > migrations. we are missing:
  - migrations > filesystem (in case someone edits the migrations directly). Should we support this? We could just have a flag where the user "opts-in" to either a declarative or a migratory path
  - database > filesystem. we might be able to use migra, but then how do we parse the files into the relevant shape? Perhaps we just dump it and let the user decide?
- Currently there is no good way to handle "unsafe" commands. (for example, if you rename `fruit` to `fruits` it will drop the table and create a new one). I have set the `tusker.toml` config to error out in these cases, but we need a way to capture these and give the user a viable way to rename their table. I don't know what that looks like yet.




## User stories


### Conflicts


There is an issue where the `migrations` folder needs to be alphabetical. This could actually fail in the following scenario:

1. User 1 branches off `main`
2. User 2 branches off `main`
3. User 1 makes changes on their branch. They generate a migrations file `1.sql`
4. User 2 makes changes on their branch. They generate a migrations file `2.sql`
5. User 2 merges in their branch. `2.sql` migration is run
6. User 1 merges in their branch. `1.sql` is not run, because `1` comes before `2`:

/migrations
|- 1.sql
|- 2.sql


Possible solution:

- When a branch is merged, we "stage" any migrations in the branch inside the `supabase_migrations` schema. We don't actually apply the migration, we simply push the changes to the migrations table with a git ref, like some sort of "queue"
- GitHub appears to have a way to block merging of a PR: https://stackoverflow.com/a/75673023/8677079
- Developers can set up a protection rule: "Require branches to be up to date before merging"