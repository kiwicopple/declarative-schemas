
# init.template: connects to postgres database and makes an copies "template1" to "template_supabase"
.PHONY: init.template
init.template:
	psql "postgresql://postgres:postgres@localhost:54322/template1" -f template1.sql

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





# 
# 
#  EXPERIMENTAL COMMANDS
# 
# 



# Adds git hooks to run migrations when switching branch
# TODO: this should pipe the output to the terminal
.PHONY: init.hooks
init.hooks:
	touch .git/hooks/post-checkout
	chmod u+x .git/hooks/post-checkout
	echo "#!/bin/bash\n\nmake db.changes && supabase db reset" >> .git/hooks/post-checkout
	@if [ ! -f .git/hooks/post-checkout ]; then \
		touch .git/hooks/post-checkout; \
		chmod +x .git/hooks/post-checkout; \
		echo "#!/bin/bash\n\n" > .git/hooks/post-checkout; \
	fi
	@if ! grep -q "make db.changes && supabase db reset" .git/hooks/post-checkout; then \
		echo "make db.changes && supabase db reset" >> .git/hooks/post-checkout; \
	fi

remove.hooks:
	rm .git/hooks/post-checkout