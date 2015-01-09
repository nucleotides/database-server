name        := target
credentials := .aws_credentials

feature: Gemfile.lock .dev_container
	bundle exec cucumber $(ARGS)

.dev_container: .image
	docker run \
	  --publish=8080:8080 \
	  --detach=true \
	  --env="AWS_ACCESS_KEY=${AWS_ACCESS_KEY}" \
	  --env="AWS_SECRET_KEY=${AWS_SECRET_KEY}" \
	  --env="SDB_DOMAIN=event-dev" \
	  $(name) > $@

kill:
	docker kill $(shell cat .dev_container)
	rm -f .dev_container

bootstrap: Gemfile.lock .aws_credentials
	docker pull clojure
	lein deps

.image: Dockerfile project.clj
	docker build --tag=$(name) .
	touch $@

$(credentials): ./script/create_aws_credentials
	$< $@

Gemfile.lock: Gemfile
	bundle install

clean:
	rm -f .image $(credentials)
