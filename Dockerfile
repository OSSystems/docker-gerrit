FROM ubuntu:16.04
MAINTAINER Gerrit Code Review Community

# Add Gerrit packages repository
RUN echo "deb http://deb.gerritforge.com/ gerrit contrib" > /etc/apt/sources.list.d/GerritForge.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1871F775

# Allow remote connectivity, sudo and gitweb dependencies
RUN apt-get update
RUN apt-key update
RUN apt-get upgrade -y
RUN apt-get -y install --no-install-recommends \
            libcgi-session-perl \
            gnupg2 \
            openssh-client \
            sudo

# Install OpenJDK and Gerrit in two subsequent transactions
# (pre-trans Gerrit script needs to have access to the Java command).
# Also, keep Gerrit package version explicit to ease updates.

RUN apt-get update \
 && apt-get -y install --no-install-recommends \
            openjdk-8-jre-headless

ENV GERRIT_VERSION 3.0.4-1

RUN apt-get update \
 && apt-get -y install --no-install-recommends \
            gerrit=$GERRIT_VERSION \
 && rm -f /var/gerrit/logs/*

RUN echo "gerrit hold" | sudo dpkg --set-selections

RUN apt-get -y dist-upgrade --no-install-recommends

ENV GERRIT_SITE /var/gerrit

RUN su gerrit -c "java -jar /var/gerrit/bin/gerrit.war init --batch --install-all-plugins -d /var/gerrit"

# Allow incoming traffic
EXPOSE 29418 8080

VOLUME ["/var/gerrit/git", "/var/gerrit/index", "/var/gerrit/cache", "/var/gerrit/db", "/var/gerrit/etc"]

# Start Gerrit
CMD /var/gerrit/bin/gerrit.sh start && tail -f $GERRIT_SITE/logs/error_log
