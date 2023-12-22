#!/bin/bash

# Nezha Agent 安装路径
NZ_AGENT_PATH="/opt/nezha/agent"
NZ_AGENT_SERVICE="/etc/init.d/nezha-agent"
AGENT_URL="https://github.com/naiba/nezha/releases/latest/download/nezha-agent_linux_amd64.tar.gz"

# 检查是否为 Alpine Linux
check_alpine() {
    if [ -f "/etc/alpine-release" ]; then
        echo "Alpine Linux detected."
    else
        echo "This script is intended for Alpine Linux only."
        exit 1
    fi
}

# 安装必要依赖
install_dependencies() {
    echo "Installing necessary dependencies..."
    apk update
    apk add curl wget tar
}

# 下载并安装 Agent
install_agent() {
    echo "Installing Nezha Agent..."
    mkdir -p $NZ_AGENT_PATH
    curl -L $AGENT_URL | tar zx -C $NZ_AGENT_PATH
}

# 设置 OpenRC 服务
setup_service() {
    echo "Setting up OpenRC service..."
    cat > $NZ_AGENT_SERVICE << EOF
#!/sbin/openrc-run

name="Nezha Agent"
description="Nezha Monitoring Agent"
command="${NZ_AGENT_PATH}/nezha-agent"
command_args="--host=\$NZ_HOST --port=\$NZ_PORT --secret=\$NZ_SECRET"
command_background="yes"
pidfile="/run/nezha-agent.pid"
start_stop_daemon_args="--background --make-pidfile"

depend() {
    need net
    after firewall
}
EOF

    chmod +x $NZ_AGENT_SERVICE
    rc-update add nezha-agent default
}

# 配置 Agent
configure_agent() {
    echo "Configuring Nezha Agent..."
    export NZ_HOST=$1
    export NZ_PORT=$2
    export NZ_SECRET=$3

    echo "Nezha Agent configured with host: $NZ_HOST, port: $NZ_PORT"
}

# 启动服务
start_service() {
    echo "Starting Nezha Agent..."
    rc-service nezha-agent start
}

# 停止服务
stop_service() {
    echo "Stopping Nezha Agent..."
    rc-service nezha-agent stop
}

# 卸载服务
uninstall_service() {
    echo "Stopping and removing Nezha Agent..."
    rc-service nezha-agent stop
    rc-update del nezha-agent default
    rm -f $NZ_AGENT_SERVICE
    rm -rf $NZ_AGENT_PATH
    echo "Nezha Agent uninstalled successfully."
}

# 主函数
main() {
    check_alpine
    install_dependencies
    install_agent
    setup_service
    if [ "$1" = "install_agent" ]; then
        configure_agent $2 $3 $4
        start_service
    else
        echo "Invalid command or insufficient arguments."
        exit 1
    fi
}

main "$@"
