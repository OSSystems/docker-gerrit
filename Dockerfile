FROM ubuntu:16.04
MAINTAINER Gerrit Code Review Community

# Add Gerrit packages repository
RUN echo "deb mirror://mirrorlist.gerritforge.com/deb gerrit contrib" > /etc/apt/sources.list.d/GerritForge.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1871F775

# Allow remote connectivity, sudo and gitweb dependencies
RUN apt-get update
RUN apt-key update
RUN apt-get -y install --no-install-recommends \
            libcgi-session-perl \
            openssh-client \
            sudo

# Install OpenJDK and Gerrit in two subsequent transactions
# (pre-trans Gerrit script needs to have access to the Java command).
# Also, keep package versions explicit to ease updates.

ENV OPENJDK_VERSION 8u171-b11-0ubuntu0.16.04.1

RUN apt-get update \
 && apt-get -y install --no-install-recommends \
            openjdk-8-jre-headless=$OPENJDK_VERSION

ENV GERRIT_VERSION 2.15.2-1

RUN apt-get update \
 && apt-get -y install --no-install-recommends \
            gerrit=$GERRIT_VERSION \
 && rm -f /var/gerrit/logs/*

USER gerrit
RUN java -jar /var/gerrit/bin/gerrit.war init --batch --install-all-plugins -d /var/gerrit

# Allow incoming traffic
EXPOSE 29418 8080

VOLUME ["/var/gerrit/git", "/var/gerrit/index", "/var/gerrit/cache", "/var/gerrit/db", "/var/gerrit/etc"]

ENV GERRIT_SITE /var/gerrit

# Start Gerrit
CMD /var/gerrit/bin/gerrit.sh start && tail -f $GERRIT_SITE/logs/error_log
