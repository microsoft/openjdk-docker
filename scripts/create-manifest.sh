#!/bin/bash

# Assembles a multi-architecture manifest list from images that were built natively on
# each architecture and pushed to the repository by digest.

dryRun=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r | --registries)
            registryTags="$2";
            shift 2
            ;;
        -R | --repository)
            repository="$2";
            shift 2
            ;;
        -a | --amd64-digest)
            amd64Digest="$2";
            shift 2
            ;;
        -A | --arm64-digest)
            arm64Digest="$2";
            shift 2
            ;;
        -D | --dryrun)
            dryRun=true
            shift
            ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
done

if [[ -z "$repository" || -z "$registryTags" ]]; then
    echo "--repository and --registries are required"
    exit 1
fi

tagArgs="-t ${registryTags//;/ -t }"
sources="${repository}@${amd64Digest} ${repository}@${arm64Digest}"

if [[ "$dryRun" == true ]]; then
    echo "[DRY-RUN] Running in dry-run mode. No changes will be made."
    echo "[DRY-RUN] Command that would be executed:"
    echo "docker buildx imagetools create ${tagArgs} ${sources}"
    exit 0
fi

if [[ -z "$amd64Digest" || -z "$arm64Digest" ]]; then
    echo "Missing an architecture digest. amd64: '$amd64Digest' arm64: '$arm64Digest'"
    exit 1
fi

az acr login -n "$ACR_NAME"

docker buildx imagetools create ${tagArgs} ${sources}

# The first tag always points at the manifest list that was just created
primaryTag="${registryTags%%;*}"
containerImageDigest=$(docker buildx imagetools inspect "$primaryTag" --format '{{json .Manifest}}' | jq -r .digest)

if [[ -z "$containerImageDigest" || "$containerImageDigest" == "null" ]]; then
    echo "Unable to resolve the digest of $primaryTag"
    exit 1
fi

echo "Created manifest list $primaryTag ($containerImageDigest)"
echo "##vso[task.setvariable variable=containerImageDigest]$containerImageDigest"
