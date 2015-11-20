FROM java
MAINTAINER Michael Barton, mail@michaelbarton.me.uk
ENV DIR /nucleotides-api
RUN mkdir -p ${DIR}/bin ${DIR}/target
COPY bin ${DIR}/bin
COPY target ${DIR}/target
COPY VERSION ${DIR}/VERSION
ADD image/start /usr/local/bin/
CMD ["start"]
