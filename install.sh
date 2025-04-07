#!/bin/bash
# install.sh：自动下载安装 dockerpull 脚本并安装到系统 PATH 中

# 定义 dockerpull 脚本的 raw URL，请替换为你实际的地址
DOCKERPULL_URL="https://raw.githubusercontent.com/huayi/dockerpull/refs/heads/main/dockerpull.sh"

echo "正在下载安装脚本..."
# 将脚本下载到临时目录
curl -sL "$DOCKERPULL_URL" -o /tmp/dockerpull

if [ $? -ne 0 ]; then
    echo "下载失败，请检查网络连接或 URL 是否正确。"
    exit 1
fi

# 赋予可执行权限
chmod +x /tmp/dockerpull

# 移动到系统 PATH 中的目录（比如 /usr/local/bin），需要 sudo 权限
echo "正在安装到 /usr/local/bin 目录..."
sudo mv /tmp/dockerpull /usr/local/bin/dockerpull

if [ $? -eq 0 ]; then
    echo "安装成功！现在你可以直接使用 'dockerpull' 命令。"
else
    echo "安装失败，请检查你是否有足够的权限。"
fi
