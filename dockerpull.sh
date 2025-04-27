#!/usr/bin/env bash
# dockerpull: 从若干镜像源下载 Docker 镜像
# 用法：
#   dockerpull <镜像名称[:标签]> [镜像源地址]
#
# 如果未指定镜像源，脚本会从用户主目录的 dockerpull.env 读取 MIRRORS 列表（空格或逗号分隔），
# 如文件不存在或未定义，则默认使用官方 Docker Hub

set -euo pipefail

# 默认环境文件和默认镜像源
ENV_FILE="$HOME/dockerpull.env"
DEFAULT_MIRRORS=("docker.io")
MIRRORS=()

usage() {
  echo "Usage: $0 <image[:tag]> [mirror]" >&2
  exit 1
}

# 参数解析
if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
fi
IMAGE="$1"
if [[ $# -eq 2 ]]; then
  MIRRORS=("$2")
else
  if [[ -f "$ENV_FILE" ]]; then
    # 读取并分割：支持逗号或空格
    raw="$(sed -e 's/,/ /g' "$ENV_FILE" | grep -Eo 'MIRRORS[[:space:]]*=.*' | cut -d'=' -f2-)"
    read -r -a MIRRORS <<< "$raw"
  fi
  # 如果 MIRRORS 仍为空，则使用默认
  if [[ ${#MIRRORS[@]} -eq 0 ]]; then
    MIRRORS=("${DEFAULT_MIRRORS[@]}")
  fi
fi

# 尝试拉取函数：stdout 返回成功的完整引用，日志走 stderr
try_pull() {
  local mirror="$1" image="$2"
  local urls=()
  if [[ "$image" == */* ]]; then
    urls=("$mirror/$image")
  else
    urls=("$mirror/library/$image" "$mirror/$image")
  fi
  for url in "${urls[@]}"; do
    echo "Trying pull $url" >&2
    if docker pull "$url" >&2; then
      echo "$url"
      return 0
    fi
  done
  return 1
}

# 主流程
final=""
for mirror in "${MIRRORS[@]}"; do
  if result=$(try_pull "$mirror" "$IMAGE"); then
    final="$result"
    break
  fi
done
if [[ -z "$final" ]]; then
  echo "All mirrors failed to pull $IMAGE" >&2
  exit 1
fi

# 重标签并清理临时标签
echo "Tagging $final as $IMAGE" >&2
docker tag "$final" "$IMAGE" >&2
echo "Removing temporary tag $final" >&2
docker rmi "$final" >&2 || true

echo "Done, image available as $IMAGE" >&2