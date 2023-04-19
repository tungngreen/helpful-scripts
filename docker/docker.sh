#!/bin/bash

declare -A private_repo_list

private_repo_list=(["ubie"]="143.248.57.47:5000")

usage_script="script usage: $(basename \$0) [-l] [-h] [-a somevalue]"

while getopts ':p:t:u:' OPTION; do
    case "$OPTION" in
        p)
            value="$OPTARG"
            if [[ -v private_repo_list[$value] ]]; then
                pvt_repo=${private_repo_list[$value]}
            else
                pvt_repo=$value
            fi
            ;;

        t)
            value="$OPTARG"
            if [[ "$value" != *":"* ]]; then
                img_tag="$value:latest"
                echo $img_tag
            else
                img_tag=$value
            fi
            ;;
        u)
            value="$OPTARG"
            if [[ -v private_repo_list[$value] ]]; then
                up_pvt_repo=${private_repo_list[$value]}
            else
                up_pvt_repo=$value
            fi
            ;;
        
        ?)
            echo $usage_script >&2
            exit 1
        ;;
    esac
done

if [[ ! -z "$pvt_repo" ]]; then
    echo "Getting the image from a private repo $pvt_repo."

    full_img_tag="$pvt_repo/$img_tag"

    docker_pull_cmd="docker pull $full_img_tag"
    echo $docker_pull_cmd

    private_repo_resp=$(eval "$docker_pull_cmd 2>&1")
fi
echo $private_repo_resp

if [[ "$private_repo_resp" == *"manifest unknown"* ]] || [[ "$private_repo_resp" == *"no route to host"* ]]; then
    echo "Failed to get the image from the private repo. Getting it from Docker Hub."

    docker_pull_cmd="docker pull $img_tag"
    eval "$docker_pull_cmd"

    if [[ ! -z $up_pvt_repo ]]; then
        echo "Pushing the image to a private repo $pvt_reg."
        pvt_docker_tag_cmd="docker image tag $img_tag $full_img_tag"
        eval "$pvt_docker_tag_cmd"
        pvt_docker_push_cmd="docker push $full_img_tag"
        eval "$pvt_docker_push_cmd"
    fi

fi

