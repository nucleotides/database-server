name   := target

Gemfile.lock: Gemfile
	bundle install

bootstrap: Gemfile.lock
	docker pull clojure
	lein deps

.image: Dockerfile project.clj
	docker build --tag=$(name) .
	touch $@

headless: .image
	docker run --publish=8080:8080 --detach=false $(name)

clean:
	rm -f image
