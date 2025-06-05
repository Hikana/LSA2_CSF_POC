#!/bin/bash

PRIMARY_REGISTRY="10.0.0.1:5000"
DR_REGISTRY="10.0.0.2:5000"

# 取得所有 repositories
repos=$(curl -s http://$PRIMARY_REGISTRY/v2/_catalog | jq -r '.repositories[]')

for repo in $repos; do
  # 取得每個 repo 的 tags
  tags=$(curl -s http://$PRIMARY_REGISTRY/v2/$repo/tags/list | jq -r '.tags[]')

  for tag in $tags; do
    full_image="$PRIMARY_REGISTRY/$repo:$tag"
    new_image="$DR_REGISTRY/$repo:$tag"

    echo "📦 正在同步 $full_image 到 $new_image"

    # 拉原始 image
    docker pull $full_image

    # 標記為 DR registry 的格式
    docker tag $full_image $new_image

    # 推送到 DR site
    docker push $new_image

    # 清理中介鏡像（可選）
    docker rmi $new_image
  done
done