FROM python:2.7
MAINTAINER Michael Barton, mail@michaelbarton.me.uk

RUN apt-get update && apt-get install unzip

RUN easy_install web.py
RUN wget https://simpledb-dev.googlecode.com/files/simpledb-dev-0.1.10.zip
RUN unzip simpledb-dev-0.1.10.zip
WORKDIR SimpleDB-Dev/src

CMD ["python", "simpledb_dev.py"]
