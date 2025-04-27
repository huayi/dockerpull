#!/usr/bin/env bash
# install.sh：自动下载安装 dockerpull 脚本并安装到系统 PATH 中，
# 并在用户主目录创建环境变量文件，默认填充 Docker 官方镜像源

set -euo pipefail

# 脚本下载 URL（可通过环境变量覆盖）
: ${DOCKERPULL_URL:="https://raw.githubusercontent.com/huayi/dockerpull/main/dockerpull.sh"}

# 下载到临时文件
TMPFILE=$(mktemp)
echo "Downloading dockerpull from $DOCKERPULL_URL..."
curl -fsSL "$DOCKERPULL_URL" -o "$TMPFILE"

# 安装到 /usr/local/bin
chmod +x "$TMPFILE"
echo "Installing to /usr/local/bin/dockerpull (requires sudo)..."
sudo mv "$TMPFILE" /usr/local/bin/dockerpull

echo "dockerpull installed successfully."

# 在用户主目录创建环境变量文件，若不存在则写入默认 Docker Hub
ENV_FILE="$HOME/dockerpull.env"
if [ ! -f "$ENV_FILE" ]; then
    cat <<EOF > "$ENV_FILE"
# dockerpull 镜像源列表文件
# 支持空格或逗号分隔多个镜像源地址
MIRRORS="docker.io"
EOF
    echo "Created default mirror list at $ENV_FILE with official Docker Hub."
else
    echo "Mirror list file already exists at $ENV_FILE, skipping creation."
fi

echo "You can edit $ENV_FILE to add more registry mirrors, e.g.:"
echo "  MIRRORS=\"docker.io registry.example.com,mirror.my.org\""