#!/bin/bash

source jdk-versions.sh

imagerepo="mcr.microsoft.com/openjdk/jdk"

distros=("ubuntu" "cbld" "mariner")

for distro in "${distros[@]}" 
do
    for version in "${java_versions[@]}"
    do
        image="${imagerepo}:${version}-${distro}"
        docker rmi --force $image
        docker pull $image
        java_version=$(docker run --rm $image /bin/bash -c "source \$JAVA_HOME/release && echo \$JAVA_VERSION")
        java_version=${java_version//[$'\t\r\n']}
        java_version=${java_version%%*( )}
        echo "Image '${image}' contains JDK version: ${java_version}"
        if [[ "${java_version}" == 17* ]]; then
            if [[ "${java_version}" != "${jdk17}" ]]; then
                echo "ERROR with image '${image}'!" | tee -a  "build.log"
                echo "  \`- Expected: ${jdk17}\. Found: ${java_version}."  | tee -a  "build.log"
            fi
        elif [[ $java_version == 16* ]]; then
            if [[ "${java_version}" != "${jdk16}" ]]; then
                echo "ERROR with image '${image}'!"  | tee -a  "build.log"
                echo "  \`- Expected: ${jdk16}\. Found: ${java_version}."  | tee -a  "build.log"
                echo "  \`- Found: ${java_version}"  | tee -a  "build.log"
            fi
        elif [[ "${java_version}" == 11* ]]; then
            if [[ "${java_version}" != "$jdk11" ]]; then
                echo "ERROR with image '${image}'!"  | tee -a  "build.log"
                echo "  \`- Expected: ${jdk11}"  | tee -a  "build.log"
                echo "  \`- Found: ${java_version}"  | tee -a  "build.log"
            fi
        else
            echo "Unknown version $java_version"  | tee -a  "build.log"
        fi
    done
done

cat build.log

lines_log=$(wc -l < build.log)

if [[ ${lines_log} > 0 ]]; then
  exit 1
fi

exit 0