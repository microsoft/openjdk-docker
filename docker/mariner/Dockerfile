FROM cblmariner.azurecr.io/base/core:1.0

# Defaults to 11 so this Dockerfile is always buildable.
# Valid values are listed in 'jdk_versions' file.
ARG JDK=11

RUN tdnf -y upgrade && \
    rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm && \
    tdnf install -y mariner-repos-ui && \
    tdnf install -y msopenjdk-$JDK --nogpgcheck

ENV JAVA_HOME=/usr/lib/jvm/msopenjdk-$JDK
