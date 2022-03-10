#!/bin/bash

# Adjust with the latest minor versions of Microsoft Build of OpenJDK
jdk17="17.0.2"
jdk16="16.0.2"
jdk11="11.0.14.1"

imagerepo="mcr.microsoft.com/openjdk/jdk"

distros=("ubuntu" "cbld" "mariner")
versions=("11" "16" "17")

for distro in "${distros[@]}" 
do
    for version in "${versions[@]}"
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
                echo "ERROR with image '${image}'!"
                echo "  \`- Expected: ${jdk17}\. Found: ${java_version}."
                exit 1
            fi
        elif [[ $java_version == 16* ]]; then
            if [[ "${java_version}" != "${jdk16}" ]]; then
                echo "ERROR with image '${image}'!"
                echo "  \`- Expected: ${jdk16}\. Found: ${java_version}."
                exit 1
            fi
        elif [[ "${java_version}" == 11* ]]; then
            if [[ "${java_version}" != "$jdk11" ]]; then
                echo "ERROR with image '${image}'!"
                echo "  \`- Expected: ${jdk11}"
                echo "Found: ${java_version}"
                exit 1
            fi
        else
            echo "Unknown version $java_version"
            exit 1
        fi
    done
done

exit 0
