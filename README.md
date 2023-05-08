# Declarative Schemas (POC)

A proof of concept for declarative schemas.

### Pre-reqs

- supabase cli
- [tusker](https://github.com/bikeshedder/tusker): `pip install tusker`
  - use virtualenv: `pip install virtualenv`
    - `source venv/bin/activate`
    - `pip install -r requirements.txt`
    - [`deactivate` when finished]


### Getting started

- Start supabase by running `supabase start`
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

- I had a lot of python warnings/issues running this - incompatibilities between versions and also mac M1 issues
- The codebase is small enough that it might be easier to replicate it into the CLI as code
- This provides filesystem > migrations. we are missing:
  - migrations > filesystem (in case someone edits the migrations directly). Should we support this? We could just have a flag where the user "opts-in" to either a declarative or a migratory path
  - database > filesystem. we might be able to use migra, but then how do we parse the files into the relevant shape? Perhaps we just dump it and let the user decide?
- Currently there is no good way to handle "unsafe" commands. (for example, if you rename `fruit` to `fruits` it will drop the table and create a new one). I have set the `tusker.toml` config to error out in these cases, but we need a way to capture these and give the user a viable way to rename their table. I don't know what that looks like yet.