#!/bin/bash

# Set expected JDK versions after the images are built
declare -A jdkversions=( ["11"]="11.0.17" ["17"]="17.0.5" ["8"]="1.8.0_352" )

# Set the base MCR repo
basemcr="mcr.microsoft.com/openjdk/jdk"

# Get current directory
basepath="$(dirname "$0")/docker"

# Build all distros and versions of OpenJDK
for d in $(ls -d $basepath/*); do
    distro=`basename $d`

    if [[ "$distro" == "test-only" ]]; then
        continue
    fi

    for f in $(ls -f $basepath/$distro/*); do
        dockerfile=`basename $f`
        jdkversion=$(echo "$dockerfile" | sed 's/[^0-9]*//g')
        image="$basemcr:${jdkversion}-${distro}"
        echo "Building image: ${image} with Dockerfile ${f}"
        docker build -t ${image} -f ${f} ${basepath}/${distro}
    done
done

# Validate all distros and versions of OpenJDK
for d in $(ls -d $basepath/*); do
    distro=`basename $d`

    for f in $(ls -f $basepath/$distro/*); do
        dockerfile=`basename $f`
        jdkversion=$(echo "$dockerfile" | sed 's/[^0-9]*//g')
        image="$basemcr:${jdkversion}-${distro}"

        if [[ "$distro" == "test-only" ]]; then
            continue
        fi

        # Validate the image
        if [[ "${distro}" == "distroless" ]]; then
            java_version=$(docker run --rm $image -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
        else
            java_version=$(docker run --rm $image /bin/bash -c "source \$JAVA_HOME/release && echo \$JAVA_VERSION")
        fi

        java_version=${java_version//[$'\t\r\n']}
        java_version=${java_version%%*( )}
        expectedversion="${jdkversions[$jdkversion]}"

        if [[ "$java_version" == "$expectedversion" ]]; then
            echo "Image '${image}' contains expected JDK version: ${expectedversion}"
        else
            echo "ERROR: Image '${image}' contains unexpected JDK version: ${java_version}"
            echo "  Expected: ${expectedversion}"
        fi
    done
done
