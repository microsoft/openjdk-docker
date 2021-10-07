FROM cblmariner.azurecr.io/base/core:1.0

MAINTAINER Microsoft OpenJDK Support <openjdk-support@microsoft.com>
LABEL "Author"="Microsoft"
LABEL "Support"="Microsoft OpenJDK Support <openjdk-support@microsoft.com>"

# Defaults to 17 so this Dockerfile is always buildable.
# Valid values are listed in 'jdk_versions' file.
ARG JDK_VERSION=17

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN tdnf -y update && \
    tdnf -y upgrade && \
    tdnf install -y tzdata ca-certificates freetype fontconfig && \
    rm -rf /var/cache/tdnf && \
    rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm && \
    tdnf install -y mariner-repos-ui && \
    tdnf install -y msopenjdk-$JDK_VERSION --nogpgcheck && \
    if [ "$JDK_VERSION" = "11" ]; then java -Xshare:dump; fi

ENV JAVA_HOME=/usr/lib/jvm/msopenjdk-$JDK_VERSION
