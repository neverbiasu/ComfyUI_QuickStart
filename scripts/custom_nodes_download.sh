#!/bin/bash

cd ComfyUI/custom_nodes

echo "Checking dependencies..."
if ! command -v jq &> /dev/null; then
    echo "jq not found. Installing jq..."
    # 检测包管理器并安装
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