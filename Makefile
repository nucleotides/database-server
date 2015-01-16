name        := target
credentials := .aws_credentials

fetch_cred  = $$(./script/get_credential $(credentials) $(1))

feature: Gemfile.lock .dev_container
	AWS_ACCESS_KEY=$(call fetch_cred,AWS_ACCESS_KEY) \
	AWS_SECRET_KEY=$(call fetch_cred,AWS_SECRET_KEY) \
	AWS_SDB_DOMAIN="event-dev" \
	AWS_REGION="us-west-1" \
	bundle exec cucumber $(ARGS)

.dev_container: .image $(credentials)
	docker run \
	  --publish=80:80 \
	  --detach=true \
	  --env="AWS_ACCESS_KEY=$(call fetch_cred,AWS_ACCESS_KEY)" \
	  --env="AWS_SECRET_KEY=$(call fetch_cred,AWS_SECRET_KEY)"\
	  --env="AWS_SDB_DOMAIN=event-dev" \
	  --env="AWS_REGION=us-west-1" \
	  $(name) > $@

.sdb_container: .sdb_image
	docker run \
	  --publish=8081:8080 \
	  --detach=true \
	  sdb > $@


repl: $(credentials)
	AWS_ACCESS_KEY=$(call fetch_cred,AWS_ACCESS_KEY) \
	AWS_SECRET_KEY=$(call fetch_cred,AWS_SECRET_KEY) \
	lein repl

irb: $(credentials)
	AWS_ACCESS_KEY=$(call fetch_cred,AWS_ACCESS_KEY) \
	AWS_SECRET_KEY=$(call fetch_cred,AWS_SECRET_KEY) \
	AWS_SDB_DOMAIN=event-dev \
	bundle exec irb

kill:
	docker kill $(shell cat .dev_container)
	rm -f .dev_container

bootstrap: Gemfile.lock $(credentials) .sdb_container
	docker pull clojure
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
	bundle install

clean:
	rm -f .image $(credentials)
