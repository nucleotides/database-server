name        := nucleotides-api
credentials := .aws_credentials

fetch_cred  = $$(./script/get_credential $(credentials) $(1))

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

################################################
#
# Consoles
#
################################################

repl: $(credentials)
	@$(params) lein repl

irb: $(credentials)
	@$(params) bundle exec ./script/irb

ssh: .rdm_container .api_image $(credentials)
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

feature: Gemfile.lock .api_container
	@$(params) bundle exec cucumber $(ARGS) --require features

test:
	@$(params) lein trampoline test $(ARGS) 2>&1 | egrep -v 'INFO|clojure.tools.logging'

autotest:
	@$(params) lein test-refresh 2>&1 | egrep -v 'INFO|clojure.tools.logging'

.api_container: .rdm_container .api_image $(credentials)
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

bootstrap: Gemfile.lock $(credentials) .rdm_container tmp/input_data
	docker pull $(shell head -n 1 Dockerfile | cut -f 2 -d ' ')
	lein deps

tmp/input_data:
	mkdir -p $(dir $@)
	git clone https://github.com/nucleotides/nucleotides-data.git $@
	cd ./$@ && \
		git reset --hard 96abff94 && \
		inputs/data/saccharopolyspora_spinosa_dsm_44228.yml


.rdm_container: .rdm_image
	docker run \
	  --env="$(db_user)" \
	  --env="$(db_pass)" \
          --publish=5433:5432 \
	  --detach=true \
	  kiasaki/alpine-postgres:9.4 > $@

.rdm_image:
	docker pull kiasaki/alpine-postgres:9.4
	touch $@

$(credentials): ./script/create_aws_credentials
	$< $@

Gemfile.lock: Gemfile
	bundle install --path vendor/bundle

clean:
	rm -f .image $(credentials)

.PHONY: test
