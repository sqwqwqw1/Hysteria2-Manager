#!/usr/bin/env bash
# Hysteria2 一键管理脚本（安装 / 卸载）
# Author: Yaodo

set -e

# ===============================
# 自动获取公网 IP
get_ip() {
    local IP=$(curl -s ipv4.icanhazip.com)
    [ -z "$IP" ] && IP=$(curl -s ipinfo.io/ip)
    if [ -z "$IP" ]; then
        echo "无法自动获取公网 IP，请手动输入:"
        read -p "请输入服务器公网 IP: " IP
    fi
    echo "$IP"
}

# ===============================
install_hysteria() {
    echo "=============================="
    echo " 开始安装 Hysteria2"
    echo "=============================="

    IP=$(get_ip)
    echo "检测到服务器公网 IP: $IP"

    # 随机端口
    DEFAULT_PORT=$(shuf -i 9000-19999 -n 1)
    read -p "请输入 Hysteria UDP 端口 (默认 $DEFAULT_PORT): " PORT
    PORT=${PORT:-$DEFAULT_PORT}

    # 密码
    read -p "请输入 Hysteria 密码 (默认随机生成): " PASS
    if [ -z "$PASS" ]; then
        PASS=$(openssl rand -base64 12)
    fi

    echo "=============================="
    echo "安装信息:"
    echo "IP: $IP"
    echo "Port: $PORT"
    echo "密码: $PASS"
    echo "=============================="

    # 系统更新及依赖
    apt update -y
    apt install -y curl wget openssl

    # 安装 Hysteria
    bash <(curl -fsSL https://get.hy2.sh/)

    # 创建证书目录
    mkdir -p /etc/hysteria

    # 生成自签 TLS 证书
    openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout /etc/hysteria/server.key \
    -out /etc/hysteria/server.crt \
    -days 3650 \
    -subj "/CN=$IP" \
    -addext "subjectAltName=IP:$IP"

    # 写入配置文件
    cat > /etc/hysteria/config.yaml <<EOF
listen: :$PORT

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: "$PASS"

bandwidth:
  up: 1 gbps
  down: 1 gbps

masquerade:
  type: proxy
  proxy:
    url: https://www.bing.com
    rewriteHost: true
EOF

    # systemd 服务
    cat > /etc/systemd/system/hysteria-server.service <<EOF
[Unit]
Description=Hysteria Server Service
After=network.target

[Service]
ExecStart=/usr/local/bin/hysteria server --config /etc/hysteria/config.yaml
Restart=always
User=root
LimitNOFILE=512000

[Install]
WantedBy=multi-user.target
EOF

    # 启动服务
    systemctl daemon-reload
    systemctl enable hysteria-server
    systemctl restart hysteria-server

    # 放行 UDP 端口（ufw）
    if command -v ufw > /dev/null; then
        ufw allow $PORT/udp
        ufw reload
    fi

    echo "=============================="
    echo " Hysteria2 安装完成"
    echo "服务器 IP: $IP"
    echo "端口: $PORT (UDP)"
    echo "密码: $PASS"
    echo "客户端需开启：允许自签证书"
    echo "=============================="
}

# ===============================
uninstall_hysteria() {
    echo "=============================="
    echo " Hysteria2 卸载"
    echo "=============================="

    # 停止服务
    if systemctl is-active --quiet hysteria-server; then
        systemctl stop hysteria-server
        echo "服务已停止"
    fi

    # 禁用开机自启
    if systemctl is-enabled --quiet hysteria-server; then
        systemctl disable hysteria-server
        echo "开机自启已取消"
    fi

    # 删除 systemd 服务文件
    if [ -f /etc/systemd/system/hysteria-server.service ]; then
        rm -f /etc/systemd/system/hysteria-server.service
        systemctl daemon-reload
        echo "systemd 服务文件已删除"
    fi

    # 删除配置目录
    if [ -d /etc/hysteria ]; then
        rm -rf /etc/hysteria
        echo "配置目录已删除"
    fi

    # 删除可执行文件
    if [ -f /usr/local/bin/hysteria ]; then
        rm -f /usr/local/bin/hysteria
        echo "Hysteria 可执行文件已删除"
    fi

    # 删除 ufw 放行端口
    read -p "是否删除 UFW 放行端口？(y/N): " delufw
    if [[ "$delufw" == "y" || "$delufw" == "Y" ]]; then
        read -p "请输入 Hysteria UDP 端口: " PORT
        if [ -n "$PORT" ]; then
            ufw delete allow $PORT/udp || true
            echo "UFW 规则已删除"
        fi
    fi

    echo "=============================="
    echo " Hysteria2 卸载完成"
    echo "=============================="
}

# ===============================
# 主程序入口
action=$1
if [ -z "$action" ]; then
    echo "请指定操作: install 或 uninstall"
    echo "用法: $0 [install|uninstall]"
    exit 1
fi

case "$action" in
    install)
        install_hysteria
        ;;
    uninstall)
        uninstall_hysteria
        ;;
    *)
        echo "参数错误: $action"
        echo "用法: $0 [install|uninstall]"
        exit 1
        ;;
esac
