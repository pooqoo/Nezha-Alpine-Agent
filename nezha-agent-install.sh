#!/bin/bash

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
command_args=""
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

# 主菜单
main_menu() {
    echo "Nezha Monitoring Agent Installation for Alpine Linux"
    echo "1. Install Agent"
    echo "2. Start Agent"
    echo "3. Stop Agent"
    echo "4. Uninstall Agent"
    echo "5. Exit"
    read -p "Please enter your choice [1-5]: " choice
    case $choice in
        1)
            check_alpine
            install_dependencies
            install_agent
            setup_service
            ;;
        2)
            start_service
            ;;
        3)
            stop_service
            ;;
        4)
            uninstall_service
            ;;
        5)
            exit 0
            ;;
        *)
            echo "Invalid choice."
            main_menu
            ;;
    esac
}

main_menu
