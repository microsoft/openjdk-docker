#!/bin/bash -x

jdkversions=(`cat jdk_versions | grep -v "# *"  | grep -v "^$"`)
distros=(`ls -1 docker`)

help() {
cat << EOF

Microsoft Build of OpenJDK - Docker Image Builder
Copyright (c) 2021, Microsoft Corporation

$ build.sh [--all] | [distro] [version]

Arguments:
   --all: builds all base images and JDK versions defined in './jdk_versions'
   [distro]: the base image to build
       Any of: ${distros[*]}
   [version]: the JDK version to use
       Any of: ${jdkversions[*]}

EOF
exit 0
}

# Builds the image with tag '$jdk-$distro'
build_image() {
  _distro=$1
  _jdk=$2
  docker build \
        --build-arg JDK=$_jdk \
        -f docker/$_distro/Dockerfile \
        -t $_jdk-$_distro docker/$_distro
}

build_all() {
  for d in ${distros[*]}; do
    for j in ${jdkversions[*]}; do
      build_image $d $j
    done
  done
  exit 0
}

build_single() {
  # Check if distro argument is valid
  if [[ ! ${distros[*]} =~ "$1" ]]; then
    echo 'Base image not available'
    exit 1
  fi

  # Check if jdk version argument is valid
  if [[ ! ${jdkversions[*]} =~ "$2" ]]; then
    echo 'JDK version not available'
    exit 1
  fi

  # Build a single image
  build_image $1 $2
}

# Check if needs to print help
if [[ "$#" -eq 0 ]] || [[ "$#" -gt "2" ]]; then help; fi

# Check if user wants to build all. Otherwise builds one, or show help message.
if [[ "$#" -eq 1 ]] && [[ '--all' == "$1" ]]; then
  echo "Building all base images and versions."
  build_all
elif [[ "$#" -eq 1 ]]; then
  echo "Invalid argument."
  exit 1
elif [ "$#" -eq 2 ]; then
  build_single $1 $2
else
  help
fi
