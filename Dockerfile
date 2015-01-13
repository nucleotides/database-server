FROM clojure
COPY . /event-api
WORKDIR /event-api
RUN lein uberjar
CMD ["java", "-jar", "target/event-api-current-standalone.jar"]
