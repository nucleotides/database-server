FROM clojure
COPY . /event-api
WORKDIR /event-api
RUN lein ring uberjar
CMD ["java", "-jar", "target/event-api-current-standalone.jar"]
