#!/bin/bash

distro=$1
jdkversion=$2
basemcr=$3

# Set the base MCR repo with a default value if not provided
DEFAULT_MCR="mcr.microsoft.com/openjdk/jdk"
basemcr="${basemcr:-$DEFAULT_MCR}"

image="${basemcr}:${jdkversion}-${distro}"

testfolder="regular"
if [[ $distro == "distroless" ]]; then
    testfolder="distroless"
fi

# Test running a Java app
for testdockerfile in $(ls -f ./docker/test-only/$testfolder/Dockerfile.*); do

    echo "Testing image: ${image} with Dockerfile ${testdockerfile}"
    filename=$(basename -- "$testdockerfile")

    docker build --build-arg IMGTOTEST=$image -t testapprunner -f $testdockerfile ./docker/test-only/

    test_output=$(docker run --rm -e JAZ_TELEMETRY_CUSTOM_VALUE="JEG-Internal" testapprunner)

    if [[ "${test_output}" =~ "SUCCESS" ]]; then
        echo "::notice title=Test '($filename)' SUCCEEDED ($jdkversion-$distro)::Image '${image}' passed test in ($filename)."
    else
        echo "::error title=Test '($filename)' FAILED ($jdkversion-$distro)::Image '${image}' failed test in ($filename)."
        exit 1
    fi
done
