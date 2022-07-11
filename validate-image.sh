#!/bin/bash

distro=$1
jdkvendor=$2
jdkversion=$3
expectedversion=$4

# Set the base MCR repo
basemcr="mcr.microsoft.com/openjdk/jdk"

dockerfile="./docker/$distro/Dockerfile.$jdkvendor-$jdkversion-jdk"
image="${basemcr}:${jdkversion}-${distro}"

# Check image is published
docker pull "${image}" > /dev/null 2>&1

if [[ $? -ne 0 ]]; then
    echo "::error title=Image not found ($jdkversion-$distro)::Container image '$image' not found!"
    exit 1
fi

# Validate the image
if [[ "${distro}" == "distroless" ]]; then
    java_version=$(docker run --rm $image -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
else
    java_version=$(docker run --rm $image /bin/bash -c "source \$JAVA_HOME/release && echo \$JAVA_VERSION")
fi

java_version=${java_version//[$'\t\r\n']}
java_version=${java_version%%*( )}

if [[ "$java_version" == "$expectedversion" ]]; then
    echo "::notice title=Validation succeeded ($jdkversion-$distro)::Image '${image}' contains expected JDK version: ${expectedversion}"
else
    echo "::error title=Wrong minor JDK version ($jdkversion-$distro)::Container image '${image}' contains unexpected JDK version: ${java_version}. Expected: ${expectedversion}."
    exit 1
fi
