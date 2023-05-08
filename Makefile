
# Checks if there are any changes on the filesystem that have not created in a migration file
.PHONY: db.changes
db.changes:
	tusker diff


# Creates a migration file with the current timestamp
.PHONY: db.commit
db.commit:
	tusker diff > supabase/migrations/$(shell date +%s)_rename.sql
	echo "Diff saved to supabase/migrations/$(shell date +%s)_rename.sql"


# make db.new.schema: creates a new schema file and stores the "create" command in _init.sql
.PHONY: db.new.schema
db.new.schema:
	touch supabase/database/$(filter-out $@,$(MAKECMDGOALS)).sql
	echo "SET search_path TO \"$(filter-out $@,$(MAKECMDGOALS))\";" >> supabase/database/$(filter-out $@,$(MAKECMDGOALS)).sql
	echo "\ncreate schema if not exists \"$(filter-out $@,$(MAKECMDGOALS))\";" >> supabase/database/_init.sql