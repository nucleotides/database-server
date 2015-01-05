FROM clojure
COPY /src/event-api /event-api
WORKDIR /event-api
CMD ["lein", "ring", "server"]
