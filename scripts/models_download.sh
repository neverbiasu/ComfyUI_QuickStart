#!/bin/bash

# Get the absolute path of the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${SCRIPT_DIR}/../ComfyUI/models"

echo "Downloading models..."

# Install Git LFS
git lfs install

clone_models() {
    local model_url=$1
    git lfs clone $model_url
    if [ $? -ne 0 ]; then
        echo "Clone failed, trying git lfs pull..."
        git lfs pull
    fi
}

wget_models() {
    local model_url=$1
    wget $model_url
    if [ $? -ne 0 ]; then
        echo "Download failed, trying git lfs pull..."
        git lfs pull
    fi
}

# Use absolute path to point to JSON file
json_file="${SCRIPT_DIR}/models_list.json"

# Check if JSON file exists
if [ ! -f "${json_file}" ]; then
    echo "Error: File not found ${json_file}"
    exit 1
fi

# Download models
while read -r model_name; do
    if [ -n "${model_name}" ]; then
        model_url=$(jq -r --arg model_name "${model_name}" '.[$model_name]' "${json_file}")
        echo "Downloading ${model_name} from ${model_url}..."
        if [[ $model_url == *".git"* ]]; then
            clone_models "${model_url}"
        elif [[ $model_url == *"huggingface.co"* ]]; then
            wget_models "${model_url}"
        else
            wget_models "${model_url}"
        fi
    fi
done < <(jq -r 'keys[]' "${json_file}")
