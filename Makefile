name        := nucleotides-api

docker_host := $(shell echo ${DOCKER_HOST} | egrep -o "\d+.\d+.\d+.\d+")

db_user := POSTGRES_USER=postgres
db_pass := POSTGRES_PASSWORD=pass
db_name := POSTGRES_NAME=postgres

ifdef docker_host
       db_host  := POSTGRES_HOST=//$(docker_host):5433
else
       db_host  := POSTGRES_HOST=//localhost:5433
endif

params := $(db_user) $(db_pass) $(db_name) $(db_host)

jar := target/nucleotides-api-$(shell cat VERSION)-standalone.jar

docker_db := @docker run \
	--env="$(db_user)" \
	--env="$(db_name)" \
	--env="PGHOST=$(docker_host)" \
	--env="PGPASSWORD=pass" \
	--env="PGUSER=postgres" \
	--env="PGPORT=5433" \
	--env="PGDATABASE=postgres" \
	--env=POSTGRES_HOST=//localhost:5433 \
	--net=host


################################################
#
# Consoles
#
################################################



repl:
	@$(params) lein repl

irb:
	@$(params) bundle exec ./script/irb

db_logs:
	docker logs $(shell cat .rdm_container) 2>&1 | less

ssh: .rdm_container .api_image
	@docker run \
	  --tty \
	  --interactive \
	  --link $(shell cat $<):postgres \
	  --env="$(db_user)" \
	  --env="$(db_pass)" \
	  --env="$(db_name)" \
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

feature: Gemfile.lock .api_container test/fixtures/testing_db_state.sql
	@$(params) bundle exec cucumber $(ARGS) --require features

test: test/fixtures/testing_db_state.sql
	@if [ ! -z "$(hard_coded_ids)" ]; then echo $(error_msg) >&1; exit 1; fi
	@$(params) lein trampoline test $(ARGS) 2>&1 | egrep -v 'INFO|clojure.tools.logging'

autotest:
	@$(params) lein test-refresh 2>&1 | egrep -v 'INFO|clojure.tools.logging'

.api_container: .rdm_container .api_image
	@docker run \
	  --detach=true \
	  --env="$(db_user)" \
	  --env="$(db_pass)" \
	  --env="$(db_name)" \
	  --env=POSTGRES_HOST=//localhost:5433 \
	  --net=host \
	  --publish 80:80 \
	  $(name) \
	  server > $@

kill:
	docker kill $(shell cat .api_container)
	rm -f .api_container

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

bootstrap: \
	Gemfile.lock \
	.rdm_container \
	tmp/input_data \
	tmp/prod_nucleotides_data \
	test/fixtures/testing_db_state.sql \
	.base_image
	lein deps

.base_image: Dockerfile
	docker pull $(shell head -n 1 Dockerfile | cut -f 2 -d ' ')
	touch $@

test/fixtures/testing_db_state.sql: .rdm_container .api_image $(shell find src data/testing resources)
	$(docker_db) \
	  --entrypoint=psql \
	  kiasaki/alpine-postgres:9.5 \
	  --command="drop schema public cascade; create schema public;"
	sleep 2
	$(docker_db) \
	  --env="$(db_pass)" \
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
	docker run \
	  --env="$(db_user)" \
	  --env="$(db_pass)" \
          --publish=5433:5432 \
	  --detach=true \
	  kiasaki/alpine-postgres:9.5 > $@

.rdm_image:
	docker pull kiasaki/alpine-postgres:9.5
	touch $@

Gemfile.lock: Gemfile
	bundle install --path vendor/bundle

clean:
	@docker kill $(shell cat .rdm_container 2> /dev/null) 2> /dev/null; true
	@docker kill $(shell cat .api_container 2> /dev/null) 2> /dev/null; true
	@rm -f .*_container test/fixtures/testing_db_state.sql

.PHONY: test
