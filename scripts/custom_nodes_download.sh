#!/bin/bash

# Get the absolute path of the script directory
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
echo "DEBUG: Script path = ${SCRIPT_PATH}"
echo "DEBUG: Script dir = ${SCRIPT_DIR}"

# Get the project root directory
PROJECT_ROOT=$(dirname "${SCRIPT_DIR}")

CUSTOM_NODES_DIR="${PROJECT_ROOT}/ComfyUI/custom_nodes"
mkdir -p "${CUSTOM_NODES_DIR}"
cd "${CUSTOM_NODES_DIR}" || exit 1
echo "DEBUG: Working directory = $(pwd)"

# Check if JSON file exists

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

# Use absolute path to point to JSON file
json_file="${SCRIPT_DIR}/custom_nodes_list.json"
echo "DEBUG: JSON file path = ${json_file}"

if [ ! -f "${json_file}" ]; then
    echo "错误: 未找到文件 ${json_file}"
    exit 1
fi

echo "Starting to download custom nodes..."

clone_repo() {
    local repo_url=$1
    if [ -n "${repo_url}" ]; then
        git clone "${repo_url}" || echo "Warning: Failed to clone ${repo_url}"
    fi
}

jq -r 'keys[]' "${json_file}" | while read -r repo_name; do
    if [ -n "${repo_name}" ]; then
        repo_url=$(jq -r --arg repo_name "${repo_name}" '.[$repo_name]' "${json_file}")
        echo "Downloading ${repo_name} from ${repo_url}..."
        clone_repo "${repo_url}"
    fi
done
