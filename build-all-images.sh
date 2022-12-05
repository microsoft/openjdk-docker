#!/bin/bash

# Set expected JDK versions after the images are built
declare -A jdkversions=( ["11"]="11.0.15" ["17"]="17.0.3" ["8"]="1.8.0_332" )

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

        # Test running a Java app
        dockerfile="./docker/test-only/Dockerfile.testapp"
        if [[ "${distro}" == "distroless" ]]; then
            dockerfile=${dockerfile}"distroless"
        fi

        docker build --build-arg IMGTOTEST=$image -t testapprunner -f $dockerfile ./docker/test-only/
        test_output=$(docker run --rm testapprunner)

        if [[ "${test_output}" =~ "Hello World" ]]; then
            echo "::notice title=Test of sample app SUCCEEDED ($jdkversion-$distro)::Image '${image}' is ABLE to run a sample Java app."
        else
            echo "::error title=Test of sample app FAILED ($jdkversion-$distro)::Image '${image}' CANNOT run a sample Java app."
        fi

    done
done
