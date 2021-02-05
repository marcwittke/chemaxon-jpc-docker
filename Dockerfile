FROM debian:buster-slim
ENV DEBIAN_FRONTEND=noninteractive

####################################################################
#
# postgres 12
#

# installation (from postgres repo since debian only ships postgres 13)...
RUN apt-get update && apt-get install -y software-properties-common gnupg2 wget gosu
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list
RUN apt-get update && apt-get install -y postgresql-12 postgresql-client-12

# configration...
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/12/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/12/main/postgresql.conf
EXPOSE 5432



####################################################################
#
# JDK 11
#

# installation (headless)
RUN apt-get update && apt-get install -y openjdk-11-jdk-headless

# configuration
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64



####################################################################
#
# JChem Postgres Cartridge
#

# installation
COPY jchem*.deb .
RUN dpkg -i $(ls -1r jchem*.deb | head -n 1)

# configuration
COPY license.cxl /etc/chemaxon/license.cxl
RUN chmod 666 /etc/chemaxon/license.cxl
ENV CHEMAXON_LICENSE_URL=/etc/chemaxon/license.cxl


####################################################################
#
# Finalization
#
#VOLUME ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql", "/var/lib/jchem-psql", "/var/log/jchem-psql", "/etc/chemaxon/"]
WORKDIR /
COPY entrypoint.sh entrypoint.sh
RUN chmod a+x entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
