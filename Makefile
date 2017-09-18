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

TESTING_DB_CONTAINER_NAME  = nucleotides-api-testing-database
TESTING_API_CONTAINER_NAME = nucleotides-api-testing-server

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

$(shell mkdir -p logs)

name  := nucleotides-api
jar   := target/nucleotides-api-$(shell cat VERSION)-standalone.jar

help:
	@echo
	@echo "make $(call BLUE,"deploy")		Push built Docker image of API to Docker registry."
	@echo "make $(call BLUE,"feature")		Run feature tests against a Docker container running the API."
	@echo "make $(call BLUE,"test")		Run unit tests."
	@echo "make $(call BLUE,"build")		Creates a jar file for the API."
	@echo "make $(call BLUE,"db_logs")		Show the current logs of the testing database."
	@echo "make $(call BLUE,"bootstrap")		Creates required files and containers for testing and building."
	@echo "make $(call BLUE,"clean")		Clean up all containers and temporary files"
	@echo "make $(call BLUE,"clean_all")		Clean up all containers, temporary files, and dependencies."
	@echo

.PHONY: deploy feature test build bootstrap clean clean_all restart kill

################################################
#
# Clean up
#
################################################

# Reset DB to clean testing state
db_reset: restart test/fixtures/initial_state.sql

# Kill database container then restart it
restart: kill_api_container kill_rdb_container .rdm_container


kill_api_container:
	$(call STATUS_MSG,Stopping any running API containers)
	@docker kill $(TESTING_API_CONTAINER_NAME) > /dev/null 2>&1; true
	@docker rm $(TESTING_API_CONTAINER_NAME) > /dev/null 2>&1; true
	$(OK)
	@rm -f .api_container

kill_rdb_container:
	$(call STATUS_MSG,Stopping any running database containers)
	@docker kill $(TESTING_DB_CONTAINER_NAME) > /dev/null 2>&1; true
	@docker rm $(TESTING_DB_CONTAINER_NAME) > /dev/null 2>&1; true
	$(OK)
	@rm -f .rdm_container

clean: kill_api_container kill_rdb_container
	$(call STATUS_MSG,Removing all intermediate files)
	@rm -rf $(bootrapped_objects) tmp
	$(OK)

clean_all: clean
	$(call STATUS_MSG,Removing dependent libraries)
	@rm -rf vendor
	$(OK)


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
	docker logs $(TESTING_DB_CONTAINER_NAME) 2>&1 | less

ssh: .rdm_container .api_image
	$(docker_db) \
		--tty \
		--interactive \
		--link $(shell cat $<):postgres \
		--name $(TESTING_API_CONTAINER_NAME) \
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

# Extra redundancy using 'trap' to ensure API container is killed tests
feature: Gemfile.lock test/fixtures/initial_state.sql .api_container
	@bash -c "trap 'make kill_api_container' EXIT; \
		 $(db_params) bundle exec cucumber $(ARGS) --require features"

test: test/fixtures/initial_state.sql
	@if [ ! -z "$(hard_coded_ids)" ]; then echo $(error_msg) >&1; exit 1; fi
	@$(db_params) lein trampoline test $(ARGS) 2>&1 | egrep -v 'INFO|clojure.tools.logging'

autotest:
	@$(db_params) lein test-refresh 2>&1 | egrep -v 'INFO|clojure.tools.logging'

# Dependency on 'kill_api_container' ensures any existing containers are removed first
.api_container: kill_api_container .rdm_container .api_image
	$(call STATUS_MSG,Starting API container)
	$(docker_db) \
		--publish 80:80 \
		--detach=true \
		--name $(TESTING_API_CONTAINER_NAME) \
		$(name) \
		server > $@
	@sleep 7 # Allow API to start up up
	$(OK)


################################################
#
# Build the project
#
################################################


build: $(jar)

.api_image: $(shell find image src resources/migrations bin) $(jar)
	$(call STATUS_MSG,Building Docker image of API)
	@docker build --tag=$(name) . > logs/build_api_image.txt 2>&1
	@touch $@
	$(OK)

$(jar): project.clj VERSION $(shell find resources) $(shell find src -name '*.clj' -o -name '*.sql')
	$(call STATUS_MSG,Building jar file of API)
	@lein uberjar > logs/build_jar.txt 2>&1
	$(OK)


################################################
#
# Bootstrap required project resources
#
################################################


bootrapped_objects = Gemfile.lock \
		     tmp/input_data \
		     tmp/prod_nucleotides_data \
		     .base_image \
		     .rdm_container \
		     test/fixtures/initial_state.sql \
		     .api_image

bootstrap: vendor/maven $(bootrapped_objects)

vendor/maven:
	$(call STATUS_MSG,Fetching clojure dependencies)
	@lein deps > logs/fetch_clojure_dependencies.txt 2>&1
	$(OK)

.base_image: Dockerfile
	$(call STATUS_MSG,Fetching base Docker image for API Docker image)
	@docker pull $(shell head -n 1 Dockerfile | cut -f 2 -d ' ') > logs/fetch_base_image.txt 2>&1
	@touch $@
	$(OK)

test/fixtures/initial_state.sql: kill_api_container .rdm_container .api_image $(shell find src data/testing resources)
	$(call STATUS_MSG,Dropping existing test database contents)
	$(docker_db) \
		--entrypoint=psql \
		kiasaki/alpine-postgres:9.5 \
		--command="drop schema public cascade; create schema public;" \
		> logs/database_migration.txt 2>&1
	$(OK)
	$(call STATUS_MSG,Migrating test database to latest state of nucleotides data)
	$(docker_db) \
		--volume=$(abspath data/testing):/data:ro \
		$(name) \
		migrate \
		> logs/database_migration.txt 2>&1
	$(OK)
	$(call STATUS_MSG,Exporting test database state to SQL file)
	$(docker_db) \
		--entrypoint=pg_dump \
		kiasaki/alpine-postgres:9.5 \
		--inserts | grep -v 'SET row_security = off;' \
		> $@
	$(OK)

tmp/prod_nucleotides_data:
	@mkdir -p $(dir $@)
	@git clone https://github.com/nucleotides/nucleotides-data.git $@ > /dev/null 2>&1

tmp/input_data:
	$(call STATUS_MSG,Fetching nucleotides input data sets)
	@mkdir -p $(dir $@)
	@git clone https://github.com/nucleotides/nucleotides-data.git $@ > logs/fetch_nucleotides_data.txt 2>&1
	@cd ./$@ && git reset --hard d08f40d > /dev/null 2>&1
	@find ./$@/inputs/data -type f ! -name 'amycolatopsis*' -delete
	@cp ./data/pseudo_real/* ./$@/inputs
	$(OK)

.rdm_container: .rdm_image
	$(call STATUS_MSG,Starting database container)
	@export $(db_params) && \
		docker run \
		--env=POSTGRES_PASSWORD="$${PGPASSWORD}" \
		--env=POSTGRES_USER="$${PGUSER}" \
		--publish=$${PGPORT}:5432 \
		--detach=true \
		--name=$(TESTING_DB_CONTAINER_NAME) \
		kiasaki/alpine-postgres:9.5 \
		> logs/database_start_up.txt 2>&1
	@touch $@
	@sleep 5
	$(OK)

.rdm_image:
	$(call STATUS_MSG,Fetching alpline postgres image)
	@docker pull kiasaki/alpine-postgres:9.5 > logs/fetch_database_container_image.txt 2>&1
	@touch $@
	$(OK)

Gemfile.lock: Gemfile
	$(call STATUS_MSG,Fetching ruby dependencies)
	@bundle install --path vendor/bundle > logs/fetch_ruby_dependencies.txt 2>&1
	$(OK)


################################################
#
# Colourise output
#
################################################

WIDTH="%-70s"

RED_COL   = \033[31m
GREEN_COL = \033[32m
BLUE_COL  = \033[34m
END       = \033[0m

BLUE  = $(shell printf "$(BLUE_COL)$(1)$(END)")
GREEN = $(shell printf "$(GREEN_COL)$(1)$(END)")

STATUS_MSG = @printf $(WIDTH) "  --> $(1)"
OK         = @echo $(call GREEN,"OK")
