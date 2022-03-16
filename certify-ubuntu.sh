#!/bin/bash

source jdk-versions.sh

imagerepo="certify-jdk"

# LTS Versions only
ubuntu_versions=("20.04" "18.04")
certifiedimages=()

for distro in "${ubuntu_versions[@]}" 
do
    for version in "${java_versions[@]}"
    do
        image="${imagerepo}:jdk-${version}-ubuntu-${distro}"
        certifiedimages+=(${image})

        docker build \
            --build-arg UBUNTU_VERSION="$distro" \
            --build-arg JAVA_VERSION="$version" \
            -t $image \
            -f ./docker/test-only/Dockerfile.ubuntu .

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

echo "All images certified:"
for ci in "${certifiedimages[@]}"
do
    echo " - ${ci}"
done

echo ""
echo "Finished."

exit 0
