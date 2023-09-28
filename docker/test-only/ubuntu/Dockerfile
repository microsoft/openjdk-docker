# DisableDockerDetector "Used for testing purposes only"
ARG IMAGE="ubuntu"
ARG UBUNTU_VERSION="22.04"
ARG JAVA_VERSION="17"

FROM ${IMAGE}:${UBUNTU_VERSION}

ARG UBUNTU_VERSION
ARG JAVA_VERSION

LABEL "Author"="Microsoft"
LABEL "Support"="Microsoft OpenJDK Support <openjdk-support@microsoft.com>"

ENV DEBIAN_FRONTEND=noninteractive

RUN     apt-get -qq update && \
        apt-get -qq upgrade && \
        apt-get -qq install --no-install-recommends tzdata ca-certificates fontconfig locales apt-transport-https wget binutils && \
        echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
        locale-gen en_US.UTF-8 && \
        wget -q https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
        dpkg -i packages-microsoft-prod.deb && \
        apt-get -qq update && \
        apt-get -qq install msopenjdk-${JAVA_VERSION} && \
        apt-get -qq purge apt-transport-https wget && \
        apt-get -qq autoremove --purge && \
        rm -rf /var/lib/apt/lists/* && \
        echo java -Xshare:dump && \
        java -Xshare:dump && \
        if [ $(uname -m) = "x86_64" ]; then ARCH="amd64"; else ARCH="arm64"; fi && \
        ln -s /usr/lib/jvm/msopenjdk-${JAVA_VERSION}-${ARCH} /usr/lib/jvm/msopenjdk-${JAVA_VERSION}

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

ENV JAVA_HOME=/usr/lib/jvm/msopenjdk-${JAVA_VERSION}
