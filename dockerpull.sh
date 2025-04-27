#!/bin/bash
# dockerpull: 从若干镜像源下载 Docker 镜像
# 用法：
#   dockerpull <镜像名称:标签> [镜像源地址]
#
# 如果指定了第二个参数，就只使用该镜像源；否则脚本会从用户主目录下的 dockerpull.env 文件读取 MIRRORS 列表，
# 按顺序尝试每个源，直到拉取成功或列表耗尽。

set -euo pipefail

# 定义默认值以避免未定义变量导致退出
MIRRORS=()
ENV_FILE="$HOME/dockerpull.env"

usage() {
    echo "Usage: $0 <镜像名称:标签> [镜像源地址]" >&2
    echo "If no 镜像源地址 provided, will read MIRRORS from $ENV_FILE" >&2
    exit 1
}

# 参数检查
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
fi

IMAGE="$1"

# 如果提供了第二个参数，则只用这个镜像源
if [ "$#" -eq 2 ]; then
    MIRRORS=("$2")
else
    # 从用户主目录下的环境文件读取 MIRRORS
    if [ ! -f "$ENV_FILE" ]; then
        echo "Error: environment file $ENV_FILE not found." >&2
        exit 1
    fi
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    if [ -z "${MIRRORS-}" ]; then
        echo "Error: MIRRORS is not defined or empty in $ENV_FILE." >&2
        exit 1
    fi
    IFS=', ' read -r -a MIRRORS <<< "${MIRRORS}"
fi

# 函数：对给定镜像源尝试拉取，仅将最终成功的镜像地址输出到 stdout，其它日志输出到 stderr
try_pull() {
    local mirror=$1
    local image=$2
    local with_lib no_lib target

    if [[ "$image" != */* ]]; then
        with_lib="$mirror/library/$image"
        no_lib="$mirror/$image"
    else
        with_lib="$mirror/$image"
        no_lib=""
    fi

    # 先尝试带 library
    if [ -n "$with_lib" ]; then
        echo "尝试：docker pull $with_lib" >&2
        if docker pull "$with_lib"; then
            target="$with_lib"
            echo "成功：$with_lib" >&2
            printf "%s" "$target"
            return 0
        else
            echo "失败：$with_lib" >&2
        fi
    fi

    # 再尝试不带 library
    if [ -n "$no_lib" ]; then
        echo "尝试：docker pull $no_lib" >&2
        if docker pull "$no_lib"; then
            target="$no_lib"
            echo "成功：$no_lib" >&2
            printf "%s" "$target"
            return 0
        else
            echo "失败：$no_lib" >&2
        fi
    fi

    return 1
}

FINAL=""
# 依次尝试每个镜像源，确保数组元素被正确引用
for m in "${MIRRORS[@]}"; do
    if result=$(try_pull "$m" "$IMAGE"); then
        FINAL="$result"
        break
    fi
done

if [ -z "$FINAL" ]; then
    echo "所有镜像源均拉取失败，请检查镜像名称或镜像源地址。" >&2
    exit 1
fi

# 重打标签
echo "打标签：docker tag $FINAL $IMAGE" >&2
docker tag "$FINAL" "$IMAGE"

# 删除中间标签并清理悬挂层
echo "删除中间标签：docker rmi $FINAL" >&2
docker rmi "$FINAL" || true

echo "清理悬挂镜像层..." >&2
docker image prune -f >&2 || true

echo "完成：最终镜像 $IMAGE 可用。" >&2
