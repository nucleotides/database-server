name        := target
credentials := .aws_credentials

fetch_cred  = $$(./script/get_credential $(credentials) $(1))

access_key := AWS_ACCESS_KEY=$(call fetch_cred,AWS_ACCESS_KEY)
secret_key := AWS_SECRET_KEY=$(call fetch_cred,AWS_SECRET_KEY)
endpoint   := AWS_ENDPOINT="https://sdb.us-west-1.amazonaws.com"
domain     := AWS_SDB_DOMAIN="event-dev"


feature: Gemfile.lock .dev_container
	$(access_key) $(secret_key) $(endpoint) $(domain) \
	bundle exec cucumber $(ARGS)

.dev_container: .image $(credentials)
	docker run \
	  --publish=80:80 \
	  --detach=true \
	  --env="$(access_key)" \
	  --env="$(secret_key)" \
	  --env="$(domain)" \
	  --env="$(endpoint)" \
	  $(name) > $@

.sdb_container: .sdb_image
	docker run \
	  --publish=8081:8080 \
	  --detach=true \
	  sdb > $@

repl: $(credentials)
	$(access_key) $(secret_key) $(endpoint) $(domain) \
	lein repl

irb: $(credentials)
	$(access_key) $(secret_key) $(endpoint) $(domain) \
	bundle exec irb

kill:
	docker kill $(shell cat .dev_container)
	rm -f .dev_container

bootstrap: Gemfile.lock $(credentials) .sdb_container
	docker pull $(shell head -n 1 Dockerfile | cut -f 2 -d ' ')
	lein deps

.image: Dockerfile project.clj $(shell find src -name "*.clj")
	docker build --tag=$(name) .
	touch $@

.sdb_image: images/simpledb-dev/Dockerfile
	docker build --tag=sdb $(dir $<)
	touch $@

$(credentials): ./script/create_aws_credentials
	$< $@

Gemfile.lock: Gemfile
	bundle install --path vendor/bundle

clean:
	rm -f .image $(credentials)
