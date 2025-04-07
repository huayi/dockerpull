#!/bin/bash
# dockerpull: 通过指定镜像源地址和镜像名称下载镜像，
# 先尝试加上 "library/" 前缀下载，如果失败再尝试不加前缀下载，
# 成功后重新打标签为原始镜像名称，并删除带有镜像源地址的标签

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <镜像源地址> <镜像名称:标签>"
    exit 1
fi

MIRROR="$1"
IMAGE="$2"

# 如果 IMAGE 中不包含 "/"，则需要尝试带 library 的下载方式
if [[ "$IMAGE" != *"/"* ]]; then
    IMAGE_WITH_LIBRARY="$MIRROR/library/$IMAGE"
    IMAGE_NO_LIBRARY="$MIRROR/$IMAGE"
else
    # 如果 IMAGE 中已经包含斜杠，则直接使用，不做 library 前缀处理
    IMAGE_WITH_LIBRARY="$MIRROR/$IMAGE"
    IMAGE_NO_LIBRARY=""
fi

success=0

# 先尝试带 library 的方式
if [ -n "$IMAGE_WITH_LIBRARY" ]; then
    echo "尝试使用带 library 前缀的镜像地址: $IMAGE_WITH_LIBRARY"
    if docker pull "$IMAGE_WITH_LIBRARY"; then
        success=1
        FINAL_IMAGE="$IMAGE_WITH_LIBRARY"
    else
        echo "带 library 前缀下载失败。"
    fi
fi

# 如果带 library 的方式未成功，并且存在不带 library 的情况，则尝试不带 library 的方式
if [ "$success" -ne 1 ] && [ -n "$IMAGE_NO_LIBRARY" ]; then
    echo "尝试使用不带 library 前缀的镜像地址: $IMAGE_NO_LIBRARY"
    if docker pull "$IMAGE_NO_LIBRARY"; then
        success=1
        FINAL_IMAGE="$IMAGE_NO_LIBRARY"
    else
        echo "不带 library 前缀下载也失败。"
    fi
fi

# 如果均未成功，则退出并提示错误
if [ "$success" -ne 1 ]; then
    echo "镜像拉取失败，请检查镜像源地址或镜像名称是否正确。"
    exit 1
fi

# 成功下载后，将镜像重新打标签为原始镜像名称（不带镜像源地址）
echo "为镜像 $FINAL_IMAGE 打标签为 $IMAGE ..."
docker tag "$FINAL_IMAGE" "$IMAGE"

# 删除带有镜像源地址的标签
echo "删除带有镜像源地址的镜像标签: $FINAL_IMAGE"
docker rmi "$FINAL_IMAGE"

echo "操作完成。"
