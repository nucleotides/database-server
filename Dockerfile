FROM clojure:lein-2.5.0
COPY . /event-api
WORKDIR /event-api
CMD ["lein", "trampoline", "run"]
