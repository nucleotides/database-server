FROM clojure:lein-2.5.0
ENV DIR /nucleotides-api
RUN mkdir -p ${DIR}/bin ${DIR}/target
COPY bin ${DIR}/bin
COPY target ${DIR}/target
COPY VERSION ${DIR}/VERSION
CMD ["/nucleotides-api/bin/server"]
