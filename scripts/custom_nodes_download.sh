#!/bin/bash

# Get the absolute path of the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${SCRIPT_DIR}/../ComfyUI/custom_nodes"

echo "Checking dependencies..."
if ! command -v jq &> /dev/null; then
    echo "jq not found. Installing jq..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y jq
    elif command -v yum &> /dev/null; then
        yum install -y jq
    elif command -v apk &> /dev/null; then
        apk add jq
    else
        echo "Error: Package manager not found. Please install jq manually."
        exit 1
    fi
fi

# Check if JSON file exists
json_file="${SCRIPT_DIR}/custom_nodes_list.json"
if [ ! -f "${json_file}" ]; then
    echo "Error: File not found ${json_file}"
    exit 1
fi

echo "Starting to download custom nodes..."

clone_repo() {
    local repo_url=$1
    if [ -n "${repo_url}" ]; then
        git clone "${repo_url}" || echo "Warning: Failed to clone ${repo_url}"
    fi
}

while read -r repo_name; do
    if [ -n "${repo_name}" ]; then
        repo_url=$(jq -r --arg repo_name "${repo_name}" '.[$repo_name]' "${json_file}")
        echo "Downloading ${repo_name} from ${repo_url}..."
        clone_repo "${repo_url}"
    fi
done < <(jq -r 'keys[]' "${json_file}")
