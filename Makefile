name        := target
credentials := .aws_credentials

fetch_cred  = $$(./script/get_credential $(credentials) $(1))

access_key := AWS_ACCESS_KEY=$(call fetch_cred,AWS_ACCESS_KEY)
secret_key := AWS_SECRET_KEY=$(call fetch_cred,AWS_SECRET_KEY)
endpoint   := AWS_ENDPOINT="https://sdb.us-west-1.amazonaws.com"
domain     := AWS_SDB_DOMAIN="event-dev"

mysql_root_pass := MYSQL_ROOT_PASSWORD=root_password
mysql_database  := MYSQL_DATABASE=dev_database
mysql_user      := MYSQL_USER=user
mysql_pass      := MYSQL_PASSWORD=pass
mysql_url       := MYSQL_URL=//$(shell echo ${DOCKER_HOST} | egrep -o "\d+.\d+.\d+.\d+"):3307

repl: $(credentials)
	$(access_key) $(secret_key) $(endpoint) $(domain) \
	$(mysql_url) $(mysql_user) $(mysql_pass) \
	lein repl

irb: $(credentials)
	$(access_key) $(secret_key) $(endpoint) $(domain) \
	bundle exec ./script/irb

kill:
	docker kill $(shell cat .api_container)
	rm -f .api_container

################################################
#
# Test project
#
################################################

feature: Gemfile.lock .api_container
	$(access_key) $(secret_key) $(endpoint) $(domain) \
	$(mysql_url) $(mysql_user) $(mysql_pass) \
	bundle exec cucumber $(ARGS)

test:
	$(access_key) $(secret_key) $(endpoint) $(domain) \
	$(mysql_url) $(mysql_user) $(mysql_pass) \
	lein trampoline test

autotest:
	lein prism

.api_container: .api_image $(credentials)
	docker run \
	  --publish=80:80 \
	  --detach=true \
	  --env="$(access_key)" \
	  --env="$(secret_key)" \
	  --env="$(domain)" \
	  --env="$(endpoint)" \
	  $(name) > $@

################################################
#
# Bootstrap required project resources
#
################################################

bootstrap: Gemfile.lock $(credentials) .sdb_container .mysql_image
	docker pull $(shell head -n 1 Dockerfile | cut -f 2 -d ' ')
	lein deps

.sdb_container: .sdb_image
	docker run \
	  --publish=8081:8080 \
	  --detach=true \
	  --rm \
	  sdb > $@

.mysql_container: .mysql_image
	docker run \
	  --publish=3307:3306 \
	  --env="$(mysql_root_pass)" \
	  --env="$(mysql_user)" \
	  --env="$(mysql_pass)" \
	  --rm \
	  mysql > $@

.api_image: Dockerfile project.clj $(shell find src -name "*.clj")
	docker build --tag=$(name) .
	touch $@

.sdb_image: images/simpledb-dev/Dockerfile
	docker build --tag=sdb $(dir $<)
	touch $@

.mysql_image:
	docker pull mysql
	touch $@

$(credentials): ./script/create_aws_credentials
	$< $@

Gemfile.lock: Gemfile
	bundle install --path vendor/bundle

clean:
	rm -f .image $(credentials)

.PHONY: test
