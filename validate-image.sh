#!/bin/bash

ARGS=""

while (( "$#" )); do
  case "$1" in
    -s|--skip-pull)
      SKIPPULL=1
      shift
      ;;
    -*|--*=)
      echo "Invalid flag: $1" >&2
      exit 1
      ;;
    *)
      ARGS="$ARGS $1"
      shift
      ;;
  esac
done

eval set -- "$ARGS"

distro=$1
jdkvendor=$2
jdkversion=$3
expectedversion=$4

# Set the base MCR repo
basemcr="mcr.microsoft.com/openjdk/jdk"

dockerfile="./docker/$distro/Dockerfile.$jdkvendor-$jdkversion-jdk"
image="${basemcr}:${jdkversion}-${distro}"

# Check image is published
if [[ "$SKIPPULL" != "1" ]]; then
  docker pull "${image}" > /dev/null 2>&1
fi

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
    echo "::error title=Wrong minor JDK version ($jdkversion-$distro)::Image '${image}' contains unexpected JDK version: ${java_version}. Expected: ${expectedversion}."
    exit 1
fi

# Test running a Java app
dockerfile="./docker/test-only/Dockerfile.testapp"
if [[ "${distro}" == "distroless" ]]; then
  dockerfile=${dockerfile}"distroless"
fi

docker build --build-arg IMGTOTEST=$image -t testapprunner -f $dockerfile .
test_output=$(docker run --rm -ti $image)

if [[ "${test_output}" =~ "Hello World" ]]; then
    echo "::notice title=Test of sample app SUCCEEDED ($jdkversion-$distro)::Image '${image}' is ABLE to run a sample Java app."
else
    echo "::error title=Test of sample app FAILED ($jdkversion-$distro)::Image '${image}' CANNOT run a sample Java app."
    exit 1
fi
