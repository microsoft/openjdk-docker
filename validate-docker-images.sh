#!/bin/bash

# Adjust with the latest minor versions of Microsoft Build of OpenJDK
jdk17="17.0.2"
jdk16="16.0.2"
jdk11="11.0.14.1"

java_versions=("11" "16" "17")

imagerepo="mcr.microsoft.com/openjdk/jdk"
distros=("ubuntu" "cbld" "mariner")
validatedimages=()

validationlog="validation-latest-images.log"

# Validate the top-level supported images
# Only latest LTS of JDK and latest LTS of the Linux distribution
for distro in "${distros[@]}" 
do
    for version in "${java_versions[@]}"
    do
        image="${imagerepo}:${version}-${distro}"
        validatedimages+=(${image})

        docker rmi --force $image
        docker pull $image
        
        java_version=$(docker run --rm $image /bin/bash -c "source \$JAVA_HOME/release && echo \$JAVA_VERSION")
        java_version=${java_version//[$'\t\r\n']}
        java_version=${java_version%%*( )}
        
        echo "Image '${image}' contains JDK version: ${java_version}" | tee -a  $validationlog
        if [[ "${java_version}" == 17* ]]; then
            if [[ "${java_version}" != "${jdk17}" ]]; then
                echo "ERROR with image '${image}'!" | tee -a  $validationlog
                echo "  \`- Expected: ${jdk17}. Found: ${java_version}."  | tee -a  $validationlog
            fi
        elif [[ $java_version == 16* ]]; then
            if [[ "${java_version}" != "${jdk16}" ]]; then
                echo "ERROR with image '${image}'!"  | tee -a  $validationlog
                echo "  \`- Expected: ${jdk16}. Found: ${java_version}."  | tee -a  $validationlog
            fi
        elif [[ "${java_version}" == 11* ]]; then
            if [[ "${java_version}" != "$jdk11" ]]; then
                echo "ERROR with image '${image}'!"  | tee -a  $validationlog
                echo "  \`- Expected: ${jdk11}. Found: ${java_version}."  | tee -a  $validationlog
            fi
        else
            echo "Unknown version $java_version"  | tee -a  $validationlog
        fi
    done
done

# Validates existing LTS releases of Ubuntu
# LTS Versions only
ubuntu_versions=("20.04" "18.04")

for distro in "${ubuntu_versions[@]}" 
do
    for version in "${java_versions[@]}"
    do
        image="${imagerepo}:jdk-${version}-ubuntu-${distro}"
        validatedimages+=(${image})

        docker build \
            --build-arg UBUNTU_VERSION="$distro" \
            --build-arg JAVA_VERSION="$version" \
            -t $image \
            -f ./docker/test-only/Dockerfile.ubuntu .

        java_version=$(docker run --rm $image /bin/bash -c "source \$JAVA_HOME/release && echo \$JAVA_VERSION")
        java_version=${java_version//[$'\t\r\n']}
        java_version=${java_version%%*( )}

        echo "Image '${image}' contains JDK version: ${java_version}" | tee -a  $validationlog
        if [[ "${java_version}" == 17* ]]; then
            if [[ "${java_version}" != "${jdk17}" ]]; then
                echo "ERROR with image '${image}'!"  | tee -a  $validationlog
                echo "  \`- Expected: ${jdk17}. Found: ${java_version}." | tee -a  $validationlog
            fi
        elif [[ $java_version == 16* ]]; then
            if [[ "${java_version}" != "${jdk16}" ]]; then
                echo "ERROR with image '${image}'!" | tee -a  $validationlog
                echo "  \`- Expected: ${jdk16}. Found: ${java_version}." | tee -a  $validationlog
            fi
        elif [[ "${java_version}" == 11* ]]; then
            if [[ "${java_version}" != "$jdk11" ]]; then
                echo "ERROR with image '${image}'!"
                echo "  \`- Expected: ${jdk11}. Found: ${java_version}" | tee -a  $validationlog
            fi
        else
            echo "ERROR: Unknown version $java_version" | tee -a  $validationlog
        fi
    done
done

echo ""
echo "Validation complete."

echo "All images validated:"
for ci in "${validatedimages[@]}"
do
    echo " - ${ci}"
done

echo ""
echo "Validation log:"
cat $validationlog

grep -q "ERROR" $validationlog

if [[ $? == 0 ]]; then
    exit 1
fi

exit 0