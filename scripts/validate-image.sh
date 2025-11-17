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

# Validate the image if expectedversion is set (not blank)
if [[ ! -z "$expectedversion" ]]; then
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
fi

# Check if CDS is enabled
if [[ "${distro}" == "distroless" ]]; then
    java_version_string=$(docker run --rm $image -version 2>&1)
else
    java_version_string=$(docker run --rm $image /bin/bash -c "java -version 2>&1")
fi

if [[ "$java_version_string" =~ "sharing" ]]; then
    echo "::notice title=CDS enabled ($jdkversion-$distro)::Image '${image}' has enabled CDS."
else
    echo "::warning title=CDS disabled ($jdkversion-$distro)::Image '${image}' has disabled CDS."
fi

# Check if jaz is present
if [[ "${distro}" == "distroless" ]]; then
    jaz_version_string=$(docker run --rm -e JAZ_PRINT_VERSION=1 --entrypoint jaz $image 2>&1)
else
    jaz_version_string=$(docker run --rm $image /bin/bash -c "JAZ_PRINT_VERSION=1 jaz 2>&1")
fi

# We simply check for the presence of jaz.
if [[ "$jaz_version_string" =~ "jaz version:" ]]; then
    echo "::notice title=JAZ present ($jdkversion-$distro)::Image '${image}' has JAZ installed."
else
    echo "::error title=JAZ missing ($jdkversion-$distro)::Image '${image}' does not have JAZ installed."
fi


# Run tests
bash ./scripts/test-image.sh $distro $jdkversion
