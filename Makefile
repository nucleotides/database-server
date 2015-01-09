name   := target

feature: Gemfile.lock .dev_container
	bundle exec cucumber $(ARGS)

Gemfile.lock: Gemfile
	bundle install

bootstrap: Gemfile.lock
	docker pull clojure
	lein deps

.image: Dockerfile project.clj
	docker build --tag=$(name) .
	touch $@

.dev_container: .image
	docker run --publish=8080:8080 --detach=true $(name) > $@

kill:
	docker kill $(shell cat .dev_container)
	rm -f .dev_container

clean:
	rm -f image
