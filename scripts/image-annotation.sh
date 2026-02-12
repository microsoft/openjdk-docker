#!/bin/bash
az acr login -n "$ACR_NAME"

if [[ $? -ne 0 ]]; then
    echo "Failed to login to ACR"
    exit 1
fi

debug=false

while getopts "r:m:d" opt; do
    case $opt in
        r)
            registry="$OPTARG"
            ;;
        m)
            manifest="$OPTARG"
            ;;
        d)
            debug=true
            ;;
        *)
            echo "Invalid option: -$OPTARG"
            exit 1
            ;;
    esac
done

if [[ -z "$manifest" ]]; then
    echo "##vso[task.logissue type=error]Container image manifest is empty or null. Unable to add annotation!"
    exit 1
fi

endOfLifeDate=$(date "+%Y-%m-%d")

echo "Annotating image ${registry}@${manifest} with end-of-life date ${endOfLifeDate}T00:00:00"

if [[ "$debug" == true ]]; then
    echo "[DRY-RUN] Running in dry-run mode. No changes will be made."
    echo "[DRY-RUN] Command that would be executed:"
    echo "oras attach --artifact-type \"application/vnd.microsoft.artifact.lifecycle\" --annotation \"vnd.microsoft.artifact.lifecycle.end-of-life.date=${endOfLifeDate}T00:00:00Z\" $registry@$manifest --verbose"
else
    oras attach \
    --artifact-type "application/vnd.microsoft.artifact.lifecycle" \
    --annotation "vnd.microsoft.artifact.lifecycle.end-of-life.date=${endOfLifeDate}T00:00:00Z" \
    $registry@$manifest \
    --verbose

    if [[ $? -ne 0 ]]; then
        echo "Failed to annotate image!"
        exit 1
    fi
fi
