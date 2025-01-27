#!/bin/bash

distro=$1
jdkversion=$2

# Set the base MCR repo
basemcr="mcr.microsoft.com/openjdk/jdk"

image="${basemcr}:${jdkversion}-${distro}"

testfolder="regular"
if [[ "$distro" == "distroless" || "$distro" == "ubuntu-chisel" ]]; then
    testfolder="distroless"
fi

# Test running a Java app
for testdockerfile in $(ls -f ./docker/test-only/$testfolder/Dockerfile.*); do
    if [[ "${testdockerfile}" =~ "ubuntu" ]]; then
     continue
    fi

    echo "Testing image: ${image} with Dockerfile ${testdockerfile}"
    filename=$(basename -- "$testdockerfile")

    docker build --build-arg IMGTOTEST=$image -t testapprunner -f $testdockerfile ./docker/test-only/

    test_output=$(docker run --rm testapprunner)

    if [[ "${test_output}" =~ "SUCCESS" ]]; then
        echo "::notice title=Test '($filename)' SUCCEEDED ($jdkversion-$distro)::Image '${image}' passed test in ($filename)."
    else
        echo "::error title=Test '($filename)' FAILED ($jdkversion-$distro)::Image '${image}' failed test in ($filename)."
        exit 1
    fi
done
