#!/bin/bash

cd ComfyUI/custom_nodes

echo "Downloading custom nodes..."

clone_repo() {
    local repo_url=$1
    git clone $repo_url
}

json_file="./custom_nodes_list.json"

for repo_name in $(jq -r 'keys[]' $json_file); do
    repo_url=$(jq -r --arg repo_name "$repo_name" '.[$repo_name]' $json_file)
    echo "Downloading $repo_name from $repo_url..."
    clone_repo $repo_url
done
