#!/bin/bash
az acr login -n "$ACR_NAME"

if [[ $? -ne 0 ]]; then
    echo "Failed to login to ACR"
    exit 1
fi

debug=false

while getopts "r:i:m:d" opt; do
    case $opt in
        r) registry="$OPTARG" ;;
        i) image="$OPTARG" ;;
        m) manifest="$OPTARG" ;;
        d) debug=true ;;
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

if [[ -z "$manifest" ]]; then
    echo "##vso[task.logissue type=error]Container image manifest is empty or null. Unable to add annotation!"
fi

endOfLifeDate=$(date "+%Y-%m-%d")

echo "Annotating image $registry/$image@$manifest with end-of-life date $endOfLifeDate"

if [[ "$debug" == "true" ]]; then
    echo "[DRY-RUN] Running in dry-run mode. No changes will be made."
    echo "[DRY-RUN] Command that would be executed:"
    echo "oras attach --artifact-type \"application/vnd.microsoft.artifact.lifecycle\" --annotation \"vnd.microsoft.artifact.lifecycle.end-of-life.date=${endOfLifeDate}T00:00:00Z\" $registry/$image@$manifest --verbose"
else
    oras attach \
    --artifact-type "application/vnd.microsoft.artifact.lifecycle" \
    --annotation "vnd.microsoft.artifact.lifecycle.end-of-life.date=${endOfLifeDate}T00:00:00Z" \
    $registry/$image@$manifest --verbose

    if [[ $? -ne 0 ]]; then
        echo "Failed to annotate image!"
        exit 1
    fi
fi

# done