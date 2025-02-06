#!/bin/bash

cd ComfyUI/models

echo "Downloading models..."

git lfs install

clone_models() {
    local model_url=$1
    git lfs clone $model_url
    if [ $? -ne 0 ]; then
        echo "Clone failed, attempting git lfs pull..."
        git lfs pull
    fi
}

wget_models() {
    local model_url=$1
    wget $model_url
    if [ $? -ne 0 ]; then
        echo "Download failed, attempting git lfs pull..."
        git lfs pull
    fi
}

json_file="scripts/models_list.json"

for model_name in $(jq -r 'keys[]' $json_file); do
    model_url=$(jq -r --arg model_name "$model_name" '.[$model_name]' $json_file)
    echo "Downloading $model_name from $model_url..."
    if [[ $model_url == *".git"* ]]; then
        clone_models $model_url
    elif [[ $model_url == *"huggingface.co"* ]]; then
        wget_models $model_url
    else
        wget_models $model_url
    fi
done
