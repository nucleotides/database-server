################################################
#
# Docker configuration
#
################################################

DOCKER_ERROR     := $(shell docker info 2>&1 | grep "Cannot connect")
DOCKER_ERROR_MSG := Docker does not appear to be running.

# Exit early if Docker is not running or available
ifdef DOCKER_ERROR
    $(error Docker does not appear to be running.)
endif

# Checks for the cases where Docker is running on a remote machine
docker_host := $(shell echo ${DOCKER_HOST} | egrep -o "\d+.\d+.\d+.\d+")


################################################
#
# Database image configuration
#
################################################

db_user := PGUSER=postgres
db_pass := PGPASSWORD=pass
db_name := PGDATABASE=postgres
db_port := PGPORT=5433

ifdef docker_host
       db_host  := PGHOST=$(docker_host)
else
       db_host  := PGHOST=localhost
endif

db_params := $(db_user) $(db_pass) $(db_name) $(db_host) $(db_port)

docker_db := @docker run \
	--env="$(db_user)" \
	--env="$(db_name)" \
	--env="$(db_pass)" \
	--env="$(db_host)" \
	--env="$(db_port)" \
	--net=host


################################################
#
# Build targets
#
################################################


name  := nucleotides-api
jar   := target/nucleotides-api-$(shell cat VERSION)-standalone.jar

help:
	@echo
	@echo "make deploy		Pushes built Docker image of API to Docker registry."
	@echo "make feature		Runs feature tests against a Docker container running the API."
	@echo "make test		Runs unit tests."
	@echo "make build		Creates a jar file for the API."
	@echo "make bootstrap		Creates required files and containers for testing and building."
	@echo "make clean		Clean up all containers and intermediate files"
	@echo

.PHONY: deploy feature test build bootstrap clean restart kill

################################################
#
# Clean up
#
################################################

# Kill all containers then restart them
restart: bootstrap kill

kill:
	@docker kill $(shell cat .rdm_container 2> /dev/null) 2> /dev/null; true
	@docker kill $(shell cat .api_container 2> /dev/null) 2> /dev/null; true
	@rm -f .*_container

clean: kill
	@rm -rf $(bootrapped_objects) tmp


################################################
#
# Consoles
#
################################################


repl:
	@$(db_params) lein repl

irb:
	@$(db_params) bundle exec ./script/irb

db_logs:
	docker logs $(shell cat .rdm_container) 2>&1 | less

ssh: .rdm_container .api_image
	$(docker_db) \
		--tty \
		--interactive \
		--link $(shell cat $<):postgres \
		$(name) \
		/bin/bash

################################################
#
# Deploy project
#
################################################


deploy: .api_image
	docker login --username=$$DOCKER_USER --password=$$DOCKER_PASS --email=$$DOCKER_EMAIL
	docker tag $(name) nucleotides/api:staging
	docker push nucleotides/api:staging


################################################
#
# Test project
#
################################################


hard_coded_ids = $(shell egrep "id = \d+" src/nucleotides/api/*.sql)
error_msg      = "ERROR: hardcoded database IDs found in .sql files.\n"

feature: Gemfile.lock .api_container test/fixtures/testing_data/initial_state.sql
	@$(db_params) bundle exec cucumber $(ARGS) --require features

test: test/fixtures/testing_data/initial_state.sql
	@if [ ! -z "$(hard_coded_ids)" ]; then echo $(error_msg) >&1; exit 1; fi
	@$(db_params) lein trampoline test $(ARGS) 2>&1 | egrep -v 'INFO|clojure.tools.logging'

autotest:
	@$(db_params) lein test-refresh 2>&1 | egrep -v 'INFO|clojure.tools.logging'

.api_container: .rdm_container .api_image
	$(docker_db) \
	  --publish 80:80 \
	  --detach=true \
	  $(name) \
	  server > $@


################################################
#
# Build the project
#
################################################


build: $(jar)

.api_image: $(shell find image src resources/migrations bin) $(jar)
	docker build --tag=$(name) .
	touch $@

$(jar): project.clj VERSION $(shell find resources) $(shell find src -name '*.clj' -o -name '*.sql')
	lein uberjar


################################################
#
# Bootstrap required project resources
#
################################################


bootrapped_objects = .rdm_container \
		     Gemfile.lock \
		     tmp/input_data \
		     tmp/prod_nucleotides_data \
		     test/fixtures/testing_data/initial_state.sql \
		     .base_image \
		     .api_image

bootstrap: $(bootrapped_objects)
	lein deps

.base_image: Dockerfile
	docker pull $(shell head -n 1 Dockerfile | cut -f 2 -d ' ')
	touch $@

test/fixtures/testing_data/initial_state.sql: .rdm_container .api_image $(shell find src data/testing resources)
	$(docker_db) \
	  --entrypoint=psql \
	  kiasaki/alpine-postgres:9.5 \
	  --command="drop schema public cascade; create schema public;"
	$(docker_db) \
	  --volume=$(abspath data/testing):/data:ro \
	  $(name) \
	  migrate
	$(docker_db) \
	  --entrypoint=pg_dump \
	  kiasaki/alpine-postgres:9.5 \
	  --inserts | grep -v 'SET row_security = off;' > $@

tmp/prod_nucleotides_data:
	mkdir -p $(dir $@)
	git clone https://github.com/nucleotides/nucleotides-data.git $@

tmp/input_data:
	mkdir -p $(dir $@)
	git clone https://github.com/nucleotides/nucleotides-data.git $@
	cd ./$@ && git reset --hard d08f40d
	find ./$@/inputs/data -type f ! -name 'amycolatopsis*' -delete
	cp ./data/pseudo_real/* ./$@/inputs

.rdm_container: .rdm_image
	@export $(db_params) && \
		docker run \
		--env=POSTGRES_PASSWORD="$${PGPASSWORD}" \
		--env=POSTGRES_USER="$${PGUSER}" \
		--publish=$${PGPORT}:5432 \
		--detach=true \
		kiasaki/alpine-postgres:9.5 > $@
	@sleep 2

.rdm_image:
	docker pull kiasaki/alpine-postgres:9.5
	touch $@

Gemfile.lock: Gemfile
	bundle install --path vendor/bundle
