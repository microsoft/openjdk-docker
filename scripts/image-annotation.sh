#!/bin/bash
az acr login -n "$ACR_NAME"

if [[ $? -ne 0 ]]; then
    echo "Failed to login to ACR"
    exit 1
fi

while getopts "r:i:d:" opt; do
    case $opt in
        r) registry="$OPTARG" ;;
        i) image="$OPTARG" ;;
        d) digest="$OPTARG" ;;
        *) echo "Invalid option: -$OPTARG" ;;
    esac
done

# IFS=';' read -ra REGISTRIES_ARRAY <<< "$REGISTRIES"

# for REGISTRY in "${REGISTRIES_ARRAY[@]}"; do
# echo "Pulling... $REGISTRY"
# echo "Pulling... $registry/$image@$digest"

# docker pull "$registry/$image@$digest"
# if [[ $? -ne 0 ]]; then
#     echo "Failed to pull image $registry/$tag"
#     exit 1
# fi

# manifest=$(docker image inspect "$registry/$tag" | jq)
# digest=$(echo $manifest | jq '.[0].RepoDigests[0]')
# digest=${digest//\"/}

if [[ -z "$digest" ]]; then
    echo "##vso[task.logissue type=warning]Digest is empty or null. Skipping annotation."
    exit 0
fi

endOfLifeDate=$(date "+%Y-%m-%d")

echo "Annotating image $registry/$image@$digest with end-of-life date $endOfLifeDate"
oras attach \
--artifact-type "application/vnd.microsoft.artifact.lifecycle" \
--annotation "vnd.microsoft.artifact.lifecycle.end-of-life.date=${endOfLifeDate}T00:00:00Z" \
$registry/$image@$digest --verbose

# oras attach \
# --artifact-type "application/vnd.microsoft.artifact.lifecycle" \
# --annotation "vnd.microsoft.artifact.lifecycle.end-of-life.date=${endOfLifeDate}T00:00:00Z" \
# $digest --verbose

if [[ $? -ne 0 ]]; then
    echo "Failed to annotate image!"
    exit 1
fi

# done