#!/bin/bash

# Build the Dockerfile.chisel-base image first
docker build -t chisel-base -f Dockerfile.chisel-base .

# Loop through all Dockerfiles in the current directory and build them
for dockerfile in Dockerfile.*; do
    if [ "$dockerfile" != "Dockerfile.chisel-base" ]; then
        image_name=$(echo $dockerfile | sed 's/Dockerfile.//')
        docker build -t $image_name -f $dockerfile .
    fi
done
