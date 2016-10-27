name        := nucleotides-api

docker_host := $(shell echo ${DOCKER_HOST} | egrep -o "\d+.\d+.\d+.\d+")

db_user := PGUSER=postgres
db_pass := PGPASSWORD=pass
db_name := PGDATABASE=postgres
db_port := PGPORT=5433

ifdef docker_host
       db_host  := PGHOST=$(docker_host)
else
       db_host  := PGHOST=localhost
endif

params := $(db_user) $(db_pass) $(db_name) $(db_host) $(db_port)

jar := target/nucleotides-api-$(shell cat VERSION)-standalone.jar

docker_db := @docker run \
	--env="$(db_user)" \
	--env="$(db_name)" \
	--env="$(db_pass)" \
	--env="$(db_host)" \
	--env="$(db_port)" \
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
	@$(params) bundle exec cucumber $(ARGS) --require features

test: test/fixtures/testing_data/initial_state.sql
	@if [ ! -z "$(hard_coded_ids)" ]; then echo $(error_msg) >&1; exit 1; fi
	@$(params) lein trampoline test $(ARGS) 2>&1 | egrep -v 'INFO|clojure.tools.logging'

autotest:
	@$(params) lein test-refresh 2>&1 | egrep -v 'INFO|clojure.tools.logging'

.api_container: .rdm_container .api_image
	$(docker_db) \
	  --publish 80:80 \
	  --detach=true \
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
	test/fixtures/testing_data/initial_state.sql \
	.base_image
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
	@export $(params) && \
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

clean:
	@docker kill $(shell cat .rdm_container 2> /dev/null) 2> /dev/null; true
	@docker kill $(shell cat .api_container 2> /dev/null) 2> /dev/null; true
	@rm -f .*_container test/fixtures/testing_data/initial_state.sql

.PHONY: test
