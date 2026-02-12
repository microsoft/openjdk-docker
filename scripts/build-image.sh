#!/bin/bash

dryRun=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -b | --base-image)
            baseImage="$2"
            shift 2
            ;;
        -g | --base-tag)
            baseTag="$2"
            shift 2
            ;;
        -i | --image)
            image="$2";
            shift 2
            ;;
        -t | --tag)
            tag="$2";
            shift 2
            ;;
        -p | --package)
            package="$2";
            shift 2
            ;;
        -d | --distribution)
            distro="$2";
            shift 2
            ;;
        -r | --registries)
            registryTags="$2";
            shift 2
            ;;
        -D | --dryrun)
            dryRun=true
            shift
            ;;
        -I | --installer-image)
            installerImg="$2";
            shift 2
            ;;
        -T | --installer-tag)
            installerTag="$2";
            shift 2
            ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
done

az acr login -n junipercontainerregistry
az acr login -n "$ACR_NAME"

docker buildx create \
    --name mybuilder \
    --driver docker-container \
    --driver-opt image=junipercontainerregistry.azurecr.io/mirror/moby/buildkit \
    --platform linux/amd64,linux/arm64 \
    --use


if [[ "$distro" != "distroless" ]]; then
    buildArgs="--build-arg IMAGE=$image --build-arg TAG=$tag --build-arg package=$package"
else
    buildArgs="--build-arg INSTALLER_IMAGE=$installerImg --build-arg INSTALLER_TAG=$installerTag --build-arg BASE_IMAGE=$baseImage --build-arg BASE_TAG=$baseTag --build-arg package=$package"
fi

registryTags="-t ${registryTags/;/ -t }"

# To push to a registry use --push
# To build locally use --output=type=image,push=false

if [[ "$dryRun" == true ]]; then
    echo "[DRY-RUN] Running in dry-run mode. No changes will be made."
    echo "[DRY-RUN] Command that would be executed:"
    echo "docker buildx build --platform linux/amd64,linux/arm64 ${buildArgs} ${registryTags} -f docker/$distro/Dockerfile.$package-jdk . --metadata-file metadata.json --push"
else

    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        ${buildArgs} \
        ${registryTags} \
        -f docker/$distro/Dockerfile.$package-jdk . \
        --metadata-file metadata.json \
        --push

    containerImageDigest=$(cat metadata.json | grep -oP '(?<="containerimage.digest": ")[^"]+')
    echo "##vso[task.setvariable variable=containerImageDigest]$containerImageDigest"
    rm metadata.json
fi