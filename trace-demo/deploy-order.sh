#!/bin/bash

# Trace Order Service Helm 部署脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 默认配置
NAMESPACE="${NAMESPACE:-trace-demo}"
RELEASE_NAME="${RELEASE_NAME:-trace-order}"
CHART_PATH="./helm/trace-order"
VALUES_FILE=""

# 打印帮助信息
print_help() {
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Trace Order Service Helm 部署脚本${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -n, --namespace     命名空间 (默认: trace-demo)"
    echo "  -r, --release       Release名称 (默认: trace-order)"
    echo "  -e, --env           环境: dev|test|prod"
    echo "  -i, --install       安装应用"
    echo "  -u, --upgrade       升级应用"
    echo "  -d, --delete        卸载应用"
    echo "  -s, --status        查看状态"
    echo "  -h, --help          显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -i -e dev                    # 安装开发环境"
    echo "  $0 -u -e prod                   # 升级生产环境"
    echo "  $0 -d                           # 卸载应用"
    echo "  $0 -s                           # 查看状态"
    echo ""
}

# 检查前置条件
check_prerequisites() {
    echo -e "${YELLOW}检查前置条件...${NC}"
    
    # 检查 kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}✗ kubectl 未安装${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ kubectl 已安装${NC}"
    
    # 检查 helm
    if ! command -v helm &> /dev/null; then
        echo -e "${RED}✗ helm 未安装${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ helm 已安装${NC}"
    
    # 检查 Chart 路径
    if [ ! -d "$CHART_PATH" ]; then
        echo -e "${RED}✗ Chart 路径不存在: $CHART_PATH${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Chart 路径存在${NC}"
    
    echo ""
}

# 安装应用
install_app() {
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}安装 Trace Order Service${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    
    local install_cmd="helm install $RELEASE_NAME $CHART_PATH --namespace $NAMESPACE --create-namespace"
    
    if [ -n "$VALUES_FILE" ]; then
        install_cmd="$install_cmd -f $VALUES_FILE"
        echo -e "${GREEN}使用配置文件: $VALUES_FILE${NC}"
    fi
    
    echo -e "${YELLOW}执行命令: $install_cmd${NC}"
    echo ""
    
    eval $install_cmd
    
    echo ""
    echo -e "${GREEN}✓ 安装完成！${NC}"
    echo ""
    echo -e "${YELLOW}下一步操作:${NC}"
    echo "  1. 查看Pod状态: kubectl get pods -n $NAMESPACE"
    echo "  2. 查看日志: kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=trace-order -f"
    echo "  3. 端口转发: kubectl port-forward -n $NAMESPACE svc/$RELEASE_NAME 8081:8081"
    echo ""
}

# 升级应用
upgrade_app() {
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}升级 Trace Order Service${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    
    local upgrade_cmd="helm upgrade $RELEASE_NAME $CHART_PATH --namespace $NAMESPACE"
    
    if [ -n "$VALUES_FILE" ]; then
        upgrade_cmd="$upgrade_cmd -f $VALUES_FILE"
        echo -e "${GREEN}使用配置文件: $VALUES_FILE${NC}"
    fi
    
    echo -e "${YELLOW}执行命令: $upgrade_cmd${NC}"
    echo ""
    
    eval $upgrade_cmd
    
    echo ""
    echo -e "${GREEN}✓ 升级完成！${NC}"
    echo ""
}

# 卸载应用
uninstall_app() {
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}卸载 Trace Order Service${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    
    read -p "确认要卸载吗? (y/N): " confirm
    if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
        echo "取消卸载"
        exit 0
    fi
    
    echo ""
    echo -e "${YELLOW}执行卸载...${NC}"
    helm uninstall $RELEASE_NAME --namespace $NAMESPACE
    
    echo ""
    echo -e "${GREEN}✓ 卸载完成！${NC}"
}

# 查看状态
show_status() {
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Trace Order Service 状态${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    
    echo -e "${GREEN}Release 状态:${NC}"
    helm status $RELEASE_NAME --namespace $NAMESPACE
    echo ""
    
    echo -e "${GREEN}Pod 状态:${NC}"
    kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=trace-order
    echo ""
    
    echo -e "${GREEN}Service 状态:${NC}"
    kubectl get svc -n $NAMESPACE -l app.kubernetes.io/name=trace-order
    echo ""
    
    echo -e "${GREEN}最近事件:${NC}"
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10
    echo ""
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--release)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -e|--env)
            ENV="$2"
            case $ENV in
                dev)
                    VALUES_FILE="$CHART_PATH/values-dev.yaml"
                    ;;
                test)
                    VALUES_FILE="$CHART_PATH/values-test.yaml"
                    ;;
                prod)
                    VALUES_FILE="$CHART_PATH/values-prod.yaml"
                    ;;
                *)
                    echo -e "${RED}✗ 未知环境: $ENV${NC}"
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        -i|--install)
            ACTION="install"
            shift
            ;;
        -u|--upgrade)
            ACTION="upgrade"
            shift
            ;;
        -d|--delete)
            ACTION="delete"
            shift
            ;;
        -s|--status)
            ACTION="status"
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            echo -e "${RED}✗ 未知选项: $1${NC}"
            print_help
            exit 1
            ;;
    esac
done

# 主逻辑
if [ -z "$ACTION" ]; then
    echo -e "${RED}✗ 请指定操作类型 (-i/-u/-d/-s)${NC}"
    print_help
    exit 1
fi

check_prerequisites

case $ACTION in
    install)
        install_app
        ;;
    upgrade)
        upgrade_app
        ;;
    delete)
        uninstall_app
        ;;
    status)
        show_status
        ;;
esac
