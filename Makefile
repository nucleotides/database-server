name        := target
credentials := .aws_credentials

fetch_cred  = $$(./script/get_credential $(credentials) $(1))

access_key := AWS_ACCESS_KEY=$(call fetch_cred,AWS_ACCESS_KEY)
secret_key := AWS_SECRET_KEY=$(call fetch_cred,AWS_SECRET_KEY)
endpoint   := AWS_ENDPOINT="https://sdb.us-west-1.amazonaws.com"
domain     := AWS_SDB_DOMAIN="event-dev"

db_user      := POSTGRES_USER=postgres
db_pass      := POSTGRES_PASSWORD=pass
db_host      := POSTGRES_HOST=//$(shell echo ${DOCKER_HOST} | egrep -o "\d+.\d+.\d+.\d+"):5433
db_name      := POSTGRES_NAME=postgres

params := \
	$(access_key) \
	$(secret_key) \
	$(endpoint) \
	$(domain) \
	$(db_host) \
	$(db_user) \
	$(db_pass) \
	$(db_name)


api-server := target/api-server-0.2.0-standalone.jar
db-build   := target/db-build-0.2.0-standalone.jar

################################################
#
# Consoles
#
################################################

repl: $(credentials)
	@$(params) lein repl

irb: $(credentials)
	@$(params) bundle exec ./script/irb

################################################
#
# Test project
#
################################################

feature: Gemfile.lock .api_container
	@$(params) bundle exec cucumber $(ARGS)

test:
	@$(params) lein trampoline test $(ARGS)

autotest:
	@$(params) lein prism

.api_container: .api_image $(credentials)
	docker run \
	  --publish=80:80 \
	  --detach=true \
	  --env="$(access_key)" \
	  --env="$(secret_key)" \
	  --env="$(domain)" \
	  --env="$(endpoint)" \
	  $(name) > $@

kill:
	docker kill $(shell cat .api_container)
	rm -f .api_container

################################################
#
# Build the project jars
#
################################################

build: $(api-server) $(db-build)

$(api-server): project.clj VERSION $(shell find resources) $(shell find src)
	lein with-profile api-server uberjar

$(db-build): project.clj VERSION $(shell find resources) $(shell find src)
	lein with-profile db-build uberjar


################################################
#
# Bootstrap required project resources
#
################################################

bootstrap: Gemfile.lock $(credentials) .sdb_container .rdm_container
	docker pull $(shell head -n 1 Dockerfile | cut -f 2 -d ' ')
	lein deps

.sdb_container: .sdb_image
	docker run \
	  --publish=8081:8080 \
	  --detach=true \
	  sdb > $@

.rdm_container: .rdm_image
	docker run \
	  --publish=5433:5432 \
	  --env="$(db_user)" \
	  --env="$(db_pass)" \
	  --detach=true \
	  postgres > $@

.api_image: Dockerfile project.clj $(shell find src -name "*.clj")
	docker build --tag=$(name) .
	touch $@

.sdb_image: images/simpledb-dev/Dockerfile
	docker build --tag=sdb $(dir $<)
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
