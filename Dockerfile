FROM frolvlad/alpine-openjdk7
MAINTAINER Michael Barton, mail@michaelbarton.me.uk
RUN apk add --update bash && rm -rf /var/cache/apk/*
ENV DIR /nucleotides-api
RUN mkdir -p ${DIR}/bin ${DIR}/target
COPY bin ${DIR}/bin
COPY target ${DIR}/target
COPY VERSION ${DIR}/VERSION
ADD image /usr/local/bin/
EXPOSE 80
CMD ["start"]
