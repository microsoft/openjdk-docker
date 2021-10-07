FROM ubuntu:focal

# Defaults to 17 so this Dockerfile is always buildable.
# Valid values are listed in 'jdk_versions' file.
ARG JDK_VERSION=17

MAINTAINER Microsoft OpenJDK Support <openjdk-support@microsoft.com>
LABEL "Author"="Microsoft"
LABEL "Support"="Microsoft OpenJDK Support <openjdk-support@microsoft.com>"

RUN DEBIAN_FRONTEND=noninteractive && \
    apt-get -qq update && \
    apt-get -qq upgrade && \
    apt-get -qq install --no-install-recommends tzdata ca-certificates fontconfig locales apt-transport-https wget && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    rm -rf /var/lib/apt/lists/* && \
    wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get -qq update && \
    apt-get -qq install msopenjdk-$JDK_VERSION && \
    apt-get -qq purge apt-transport-https wget && \
    apt-get -qq autoremove --purge && \
    rm -rf /var/lib/apt/lists/* && \
    if [ "$JDK_VERSION" = "11" ]; then java -Xshare:dump; fi

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

ENV JAVA_HOME=/usr/lib/jvm/msopenjdk-$JDK_VERSION-amd64
