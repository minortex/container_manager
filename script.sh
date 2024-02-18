#!/bin/bash

action=$1
name=$2
path=$3

if [ -z "$path" ]; then
  path=$(pwd)
fi

case $action in
  pull )
    # 传递镜像名，tag
    image=$name
    tag="latest"

    # 获取token
    token=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$image:pull" | jq -r .token)
    # echo "Token is: $token"

    # 获取manifest list
    manifestList=$(curl -s -H "Authorization: Bearer $token" -H 'Accept: application/vnd.docker.distribution.manifest.list.v2+json' "https://registry-1.docker.io/v2/$image/manifests/$tag")
    # echo "Manifest list is: $manifestList"

    # 使用jq工具，从manifest list中提取amd64架构的镜像清单摘要
    amd64digest=$(echo "$manifestList" | jq -r '.manifests[] | select(.platform.architecture=="amd64") | .digest')
    # echo "amd64 digest is: $amd64digest"

    # 使用提取到的digest获取amd64的镜像清单
    manifest=$(curl -s -H "Authorization: Bearer $token" -H 'Accept: application/vnd.oci.image.manifest.v1+json' "https://registry-1.docker.io/v2/$image/manifests/$amd64digest")
    # echo "Manifest is: $manifest"

    # 解析清单并提取镜像层
    layer=$(echo "$manifest" | jq -r .layers[0].digest)
    echo "Layer is: $layer"

    # 创建一个新的文件夹用于存放合并后的文件，将 "/" 替换为 "_"
    image_folder=$(echo $image | tr "/" "_")
    mkdir -p "$image_folder"

    # 下载并解压镜像层到文件夹
    echo "Downloading: $layer"
    curl -L -H "Authorization: Bearer $token" "https://registry-1.docker.io/v2/$image/blobs/$layer" -o "$image_folder/image.tar.gz"
    tar -xzf "$image_folder/image.tar.gz" -C "$image_folder"
    rm $image_folder/image.tar.gz
    echo "Unzipped: $layer"

    # 拉取结束，开始创建OCI Bundle
    cd $image_folder
    mkdir rootfs

    # 使用find命令排除rootfs，将当前目录下的其它所有文件和目录移动到rootfs目录中。
    find . -maxdepth 1 -mindepth 1 ! -name rootfs -exec mv {} ./rootfs \;

    # 创建config.json
    runc spec;; 
  create )
    runc create --bundle $path $name ;;
  run )
    runc run --bundle $path $name ;;
  stop )
    runc stop $name ;;
  help )
    echo "A simple script to use runc."
    echo -e "Usage: script.sh [actions] [name] [path/url]\n"
    echo -e "  actions:\n\tpull\n\tcreate\n\trun\n\tstop\n"
    echo "[name] and [url] must be specified. [path] can be blanked, will use current dir." ;;
  * )
    echo "bad argument." ;;
esac  
