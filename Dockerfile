ARG DSPACE_SOURCE_CODE=https://github.com/ibict-br2/repositorio-padrao/archive/dspace-6_x.zip

FROM alpine as CLONE_CODE
ARG DSPACE_SOURCE_CODE

RUN wget -O dspace.zip $DSPACE_SOURCE_CODE \
 && unzip dspace.zip \
 && mv repositorio-padrao-dspace-6_x dspace

FROM maven:3.6-openjdk-8-slim as MAVEN_BUILD
COPY --from=CLONE_CODE /dspace /dspace
WORKDIR /dspace
RUN apt-get update \
 && apt-get install -y git \
 && apt-get clean -y
RUN mvn dependency:go-offline -B
RUN mvn package

FROM openjdk:8-alpine as ANT_BUILD
ENV ANT_VERSION=1.8.0
ENV ANT_HOME=/opt/ant
RUN apk add --clean wget \
    && wget --no-check-certificate --no-cookies http://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz \
    && tar -zvxf apache-ant-${ANT_VERSION}-bin.tar.gz -C /opt/ \
    && ln -s /opt/apache-ant-${ANT_VERSION} /opt/ant \
    && rm -f apache-ant-${ANT_VERSION}-bin.tar.gz
COPY --from=MAVEN_BUILD /dspace /dspace
WORKDIR /dspace/dspace/target/dspace-installer
RUN /opt/ant/bin/ant fresh_install

FROM tomcat:7.0-jdk8-openjdk-slim
RUN useradd -m dspace
COPY --from=ANT_BUILD --chown=dspace:dspace /dspace/webapps/* $CATALINA_HOME/webapps

USER dspace

CMD [ "/etc/init.d/tomcat", "start" ]


# createuser --username=postgres --no-superuser --pwprompt dspace
# createdb --username=postgres --owner=dspace --encoding=UNICODE dspace
# psql --username=postgres dspace -c "CREATE EXTENSION pgcrypto;"
# cd [dspace-source]/dspace/config/
# cp local.cfg.EXAMPLE local.cfg
# vi local.cfg
# 
# [dspace]/bin/dspace create-administrator

