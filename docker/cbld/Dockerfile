FROM sbidprod.azurecr.io/quinault

# Defaults to 11 so this Dockerfile is always buildable. 
# Valid values are listed in 'jdk_versions' file.
ARG JDK=11

RUN apt-get -qq update && \
    apt-get -qq upgrade && \
    apt-get -qq install apt-transport-https binutils && \
    echo "deb https://packages.microsoft.com/repos/cbl-d quinault-universe main" >> /etc/apt/sources.list && \
    apt-get -qq update && \
    apt-get -qq install msopenjdk-$JDK && \
    apt-get -qq purge apt-transport-https && \
    apt-get -qq autoremove --purge && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/msopenjdk-$JDK-amd64
