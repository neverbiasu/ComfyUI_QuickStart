#!/bin/bash

# Get the absolute path of the script directory
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
echo "DEBUG: Script path = ${SCRIPT_PATH}"
echo "DEBUG: Script dir = ${SCRIPT_DIR}"

# Get the project root directory
PROJECT_ROOT=$(dirname "${SCRIPT_DIR}")

# Create models directory
MODELS_DIR="${PROJECT_ROOT}/ComfyUI/models"
mkdir -p "${MODELS_DIR}"
cd "${MODELS_DIR}" || exit 1
echo "DEBUG: Working directory = $(pwd)"

echo "Downloading models..."

# Install Git LFS
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
sudo apt-get install git-lfs
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

download_value() {
    local key=$1
    local value=$2
    local current_path=$3

    # Create target directory
    local target_dir
    if [ -z "${current_path}" ]; then
        target_dir="${MODELS_DIR}/${key}"
    else
        target_dir="${MODELS_DIR}/${current_path}/${key}"
    fi
    target_dir=$(echo "$target_dir" | sed 's#/\+#/#g')

    if [ ! -d "${target_dir}" ]; then
        mkdir -p "${target_dir}"
    fi
    
   if ! cd "${target_dir}"; then
        echo "Error: Cannot access directory ${target_dir}"
        return 1
    fi
    
    echo "DEBUG: Current directory = $(pwd)"

    case $type in
        "string")
            echo "Downloading ${key} to ${target_dir}..."
            if [[ $value == *".git"* ]]; then
                clone_models "$value"
            else
                wget_models "$value"
            fi
            ;;
        "array")
            echo "Processing array ${key}..."
            echo "$value" | jq -c '.[]' | while read -r url; do
                url=$(echo "$url" | tr -d '"')
                if [[ $url == *".git"* ]]; then
                    clone_models "$url"
                else
                    wget_models "$url"
                fi
            done
            ;;
        "object")
            echo "Processing object ${key}..."
            echo "$value" | jq -r 'keys[]' | while read -r subkey; do
                subvalue=$(echo "$value" | jq -r --arg k "$subkey" '.[$k]')
                if [ "$subkey" = "root" ]; then
                    download_value "$subkey" "$subvalue" "${current_path}"
                else
                    download_value "$subkey" "$subvalue" "${current_path}/${key}"
                fi
            done
            ;;
    esac
}

# Use absolute path to point to JSON file
json_file="${SCRIPT_DIR}/models_list.json"

# Check if JSON file exists
if [ ! -f "${json_file}" ]; then
    echo "Error: File not found ${json_file}"
    exit 1
fi

# Download models
jq -r 'keys[]' "${json_file}" | while read -r key; do
    if [ -n "${key}" ]; then
        value=$(jq -r --arg k "$key" '.[$k]' "${json_file}")
        echo "Processing ${key}..."
        download_value "$key" "$value" ""
    fi
done
