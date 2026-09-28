#!/bin/bash

dryRun=false
pushByDigest=false
platform="linux/amd64,linux/arm64"

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
        -R | --repository)
            repository="$2";
            shift 2
            ;;
        -P | --platform)
            platform="$2";
            shift 2
            ;;
        -B | --push-by-digest)
            pushByDigest=true
            shift
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

if [[ "$pushByDigest" == true && -z "$repository" ]]; then
    echo "--repository is required when using --push-by-digest"
    exit 1
fi

if [[ "$pushByDigest" == false && -z "$registryTags" ]]; then
    echo "--registries is required unless using --push-by-digest"
    exit 1
fi

az acr login -n junipercontainerregistry
az acr login -n "$ACR_NAME"

# Recreate the builder so re-used agents do not fail on an existing instance
docker buildx rm --force mybuilder > /dev/null 2>&1 || true

docker buildx create \
    --name mybuilder \
    --driver docker-container \
    --driver-opt image=junipercontainerregistry.azurecr.io/mirror/moby/buildkit \
    --platform "$platform" \
    --use


if [[ "$distro" != "distroless" ]]; then
    buildArgs="--build-arg IMAGE=$image --build-arg TAG=$tag --build-arg package=$package"
else
    buildArgs="--build-arg INSTALLER_IMAGE=$installerImg --build-arg INSTALLER_TAG=$installerTag --build-arg BASE_IMAGE=$baseImage --build-arg BASE_TAG=$baseTag --build-arg package=$package"
fi

# When building a single architecture natively the image is pushed by digest only; the
# multi-architecture manifest list is assembled from those digests in a later step.
if [[ "$pushByDigest" == true ]]; then
    outputArgs="--output type=image,name=${repository},push-by-digest=true,name-canonical=true,push=true"
else
    # To push to a registry use --push
    # To build locally use --output=type=image,push=false
    outputArgs="${registryTags/;/ -t }"
    outputArgs="-t ${outputArgs} --push"
fi

if [[ "$dryRun" == true ]]; then
    echo "[DRY-RUN] Running in dry-run mode. No changes will be made."
    echo "[DRY-RUN] Command that would be executed:"
    echo "docker buildx build --platform ${platform} ${buildArgs} ${outputArgs} -f docker/$distro/Dockerfile.$package-jdk . --metadata-file metadata.json"
else

    docker buildx build \
        --platform "${platform}" \
        ${buildArgs} \
        ${outputArgs} \
        -f docker/$distro/Dockerfile.$package-jdk . \
        --metadata-file metadata.json

    containerImageDigest=$(cat metadata.json | grep -oP '(?<="containerimage.digest": ")[^"]+')

    if [[ "$pushByDigest" == true ]]; then
        echo "##vso[task.setvariable variable=containerImageDigest;isOutput=true]$containerImageDigest"
    else
        echo "##vso[task.setvariable variable=containerImageDigest]$containerImageDigest"
    fi

    rm metadata.json
fi
