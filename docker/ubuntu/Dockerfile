FROM ubuntu:20.04

# Defaults to 11 so this Dockerfile is always buildable.
# Valid values are listed in 'jdk_versions' file.
ARG JDK=11

RUN apt-get -qq update && \
    apt-get -qq upgrade && \
    apt-get -qq install apt-transport-https wget && \
    wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get -qq update && \
    apt-get -qq install msopenjdk-$JDK && \
    apt-get -qq purge apt-transport-https wget && \
    apt-get -qq autoremove --purge && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/msopenjdk-$JDK-amd64
