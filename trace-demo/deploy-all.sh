#!/bin/bash

# Trace Demo 多服务 Helm 部署脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
NAMESPACE="${NAMESPACE:-trace-demo}"
ACTION=""
SERVICE=""
ENV=""

# 打印帮助信息
print_help() {
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Trace Demo 多服务 Helm 部署脚本${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -n, --namespace     命名空间 (默认: trace-demo)"
    echo "  -s, --service       服务名称: order|inventory|gateway|all"
    echo "  -e, --env           环境: dev|test|prod"
    echo "  -i, --install       安装应用"
    echo "  -u, --upgrade       升级应用"
    echo "  -d, --delete        卸载应用"
    echo "  -st, --status       查看状态"
    echo "  -h, --help          显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -i -s order -e dev              # 安装订单服务开发环境"
    echo "  $0 -i -s all -e prod               # 安装所有服务生产环境"
    echo "  $0 -u -s gateway -e test           # 升级网关服务测试环境"
    echo "  $0 -d -s order                     # 卸载订单服务"
    echo "  $0 -st -s all                      # 查看所有服务状态"
    echo ""
}

# 检查前置条件
check_prerequisites() {
    echo -e "${YELLOW}检查前置条件...${NC}"
    
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}✗ kubectl 未安装${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ kubectl 已安装${NC}"
    
    if ! command -v helm &> /dev/null; then
        echo -e "${RED}✗ helm 未安装${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ helm 已安装${NC}"
    
    echo ""
}

# 部署单个服务
deploy_service() {
    local service=$1
    local action=$2
    local env=$3
    
    local chart_path="./helm/trace-${service}"
    local release_name="trace-${service}"
    local values_file=""
    
    # 确定values文件
    case $env in
        dev)
            values_file="$chart_path/values-dev.yaml"
            ;;
        test)
            values_file="$chart_path/values-test.yaml"
            ;;
        prod)
            values_file="$chart_path/values-prod.yaml"
            ;;
        *)
            echo -e "${RED}✗ 未知环境: $env${NC}"
            return 1
            ;;
    esac
    
    # 检查Chart是否存在
    if [ ! -d "$chart_path" ]; then
        echo -e "${RED}✗ Chart不存在: $chart_path${NC}"
        return 1
    fi
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}处理服务: ${service^^}${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    case $action in
        install)
            echo -e "${YELLOW}安装 $service ($env)...${NC}"
            helm install $release_name $chart_path \
                --namespace $NAMESPACE \
                --create-namespace \
                -f $values_file
            ;;
        upgrade)
            echo -e "${YELLOW}升级 $service ($env)...${NC}"
            helm upgrade $release_name $chart_path \
                --namespace $NAMESPACE \
                -f $values_file
            ;;
        delete)
            echo -e "${RED}卸载 $service...${NC}"
            helm uninstall $release_name --namespace $NAMESPACE || true
            ;;
        status)
            echo -e "${YELLOW}$service 状态:${NC}"
            helm status $release_name --namespace $NAMESPACE 2>/dev/null || echo "未安装"
            echo ""
            kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=trace-${service} 2>/dev/null || echo "无Pod"
            echo ""
            ;;
    esac
    
    echo ""
}

# 主逻辑
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -s|--service)
            SERVICE="$2"
            shift 2
            ;;
        -e|--env)
            ENV="$2"
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
        -st|--status)
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

# 验证参数
if [ -z "$ACTION" ]; then
    echo -e "${RED}✗ 请指定操作类型 (-i/-u/-d/-st)${NC}"
    print_help
    exit 1
fi

if [ -z "$SERVICE" ]; then
    echo -e "${RED}✗ 请指定服务名称 (-s order|inventory|gateway|all)${NC}"
    print_help
    exit 1
fi

if [ "$ACTION" != "status" ] && [ "$ACTION" != "delete" ] && [ -z "$ENV" ]; then
    echo -e "${RED}✗ 请指定环境 (-e dev|test|prod)${NC}"
    print_help
    exit 1
fi

check_prerequisites

# 执行部署
case $SERVICE in
    order)
        deploy_service "order" "$ACTION" "$ENV"
        ;;
    inventory)
        deploy_service "inventory" "$ACTION" "$ENV"
        ;;
    gateway)
        deploy_service "gateway" "$ACTION" "$ENV"
        ;;
    all)
        # 按依赖顺序部署：先后端服务，后网关
        if [ "$ACTION" = "install" ] || [ "$ACTION" = "upgrade" ]; then
            deploy_service "inventory" "$ACTION" "$ENV"
            deploy_service "order" "$ACTION" "$ENV"
            deploy_service "gateway" "$ACTION" "$ENV"
        else
            deploy_service "order" "$ACTION" "$ENV"
            deploy_service "inventory" "$ACTION" "$ENV"
            deploy_service "gateway" "$ACTION" "$ENV"
        fi
        ;;
    *)
        echo -e "${RED}✗ 未知服务: $SERVICE${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}操作完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if [ "$ACTION" = "install" ] || [ "$ACTION" = "upgrade" ]; then
    echo -e "${YELLOW}下一步操作:${NC}"
    echo "  1. 查看所有Pod: kubectl get pods -n $NAMESPACE"
    echo "  2. 查看日志: kubectl logs -n $NAMESPACE -l app.kubernetes.io/instance=trace-gateway -f"
    echo "  3. 端口转发网关: kubectl port-forward -n $NAMESPACE svc/trace-gateway 8080:8080"
    echo "  4. 测试访问: curl http://localhost:8080/order/health"
    echo ""
fi
