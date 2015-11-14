name        := target
credentials := .aws_credentials

fetch_cred  = $$(./script/get_credential $(credentials) $(1))

docker_host := $(shell echo ${DOCKER_HOST} | egrep -o "\d+.\d+.\d+.\d+")

db_user      := POSTGRES_USER=postgres
db_pass      := POSTGRES_PASSWORD=pass
db_name      := POSTGRES_NAME=postgres
ifdef docker_host
	db_host  := POSTGRES_HOST=//$(docker_host):5433
else
	db_host  := POSTGRES_HOST=//localhost:5433
endif

params := \
	$(db_host) \
	$(db_user) \
	$(db_pass) \
	$(db_name)

jar := target/nucleotides-api-0.2.0-standalone.jar

################################################
#
# Consoles
#
################################################

repl: $(credentials)
	@$(params) lein repl

irb: $(credentials)
	@$(params) bundle exec ./script/irb

ssh: .api_image $(credentials)
	@docker run \
	  --tty \
	  --interactive \
	  --env="$(db_host)" \
	  --env="$(db_user)" \
	  --env="$(db_pass)" \
	  --env="$(db_name)" \
	  $(name) \
	  /bin/bash

################################################
#
# Test project
#
################################################

feature: Gemfile.lock .api_container
	@$(params) bundle exec cucumber $(ARGS) --require features

test:
	@$(params) lein trampoline test $(ARGS) 2>&1 | egrep -v 'INFO|clojure.tools.logging'

autotest:
	@$(params) lein prism 2>&1 | egrep -v 'INFO|clojure.tools.logging'

.api_container: .api_image $(credentials)
	@docker run \
	  --publish=80:80 \
	  --detach=true \
	  --env="$(db_host)" \
	  --env="$(db_user)" \
	  --env="$(db_pass)" \
	  --env="$(db_name)" \
	  $(name) > $@

kill:
	docker kill $(shell cat .api_container)
	rm -f .api_container

################################################
#
# Build the project jars
#
################################################

build: $(jar)

$(jar): project.clj VERSION $(shell find resources) $(shell find src)
	lein uberjar

################################################
#
# Bootstrap required project resources
#
################################################

bootstrap: Gemfile.lock $(credentials) .rdm_container
	docker pull $(shell head -n 1 Dockerfile | cut -f 2 -d ' ')
	lein deps

.rdm_container: .rdm_image
	docker run \
	  --publish=5433:5432 \
	  --env="$(db_user)" \
	  --env="$(db_pass)" \
	  --detach=true \
	  postgres > $@

.api_image: Dockerfile $(jar)
	docker build --tag=$(name) .
	touch $@

.rdm_image:
	docker pull postgres
	touch $@

$(credentials): ./script/create_aws_credentials
	$< $@

Gemfile.lock: Gemfile
	bundle install --path vendor/bundle

clean:
	rm -f .image $(credentials)

.PHONY: test
