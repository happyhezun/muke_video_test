#!/bin/bash

# 多环境配置文件验证脚本
# 用途: 检查所有环境的配置文件是否正确创建

set -e

echo "=========================================="
echo "  Trace Demo 多环境配置验证"
echo "=========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 服务列表
services=("trace-order" "trace-inventory" "trace-gateway")
# 环境列表
environments=("dev" "test" "prod")

# 验证函数
check_files() {
    local service=$1
    local base_path="src/main/resources"
    
    echo -e "${YELLOW}----------------------------------------${NC}"
    echo -e "${YELLOW}服务: $service${NC}"
    echo -e "${YELLOW}----------------------------------------${NC}"
    
    # 检查主配置文件
    if [ -f "$base_path/application.yml" ]; then
        echo -e "  ${GREEN}✓${NC} application.yml (主配置)"
        
        # 检查是否包含 profile 激活配置
        if grep -q "@spring.profiles.active@" "$base_path/application.yml"; then
            echo -e "    ${GREEN}✓${NC} 包含 Maven profile 占位符"
        else
            echo -e "    ${RED}✗${NC} 缺少 Maven profile 占位符"
        fi
    else
        echo -e "  ${RED}✗${NC} application.yml 缺失"
    fi
    
    # 检查各环境配置文件
    for env in "${environments[@]}"; do
        local env_file="$base_path/application-${env}.yml"
        if [ -f "$env_file" ]; then
            echo -e "  ${GREEN}✓${NC} application-${env}.yml"
            
            # 检查是否包含正确的 profile 标识
            if grep -q "on-profile: $env" "$env_file"; then
                echo -e "    ${GREEN}✓${NC} Profile 标识正确"
            else
                echo -e "    ${YELLOW}⚠${NC} 未找到 Profile 标识(可能使用其他方式)"
            fi
        else
            echo -e "  ${RED}✗${NC} application-${env}.yml 缺失"
        fi
    done
    
    echo ""
}

# 执行验证
echo "检查配置文件结构..."
echo ""

for service in "${services[@]}"; do
    cd "$service"
    check_files "$service"
    cd ..
done

# 检查父 POM
echo -e "${YELLOW}----------------------------------------${NC}"
echo -e "${YELLOW}父 POM 配置${NC}"
echo -e "${YELLOW}----------------------------------------${NC}"

if [ -f "pom.xml" ]; then
    echo -e "  ${GREEN}✓${NC} pom.xml 存在"
    
    if grep -q "<profiles>" "pom.xml"; then
        echo -e "  ${GREEN}✓${NC} 包含 Maven profiles 配置"
    else
        echo -e "  ${RED}✗${NC} 缺少 Maven profiles 配置"
    fi
    
    if grep -q "spring.profiles.active" "pom.xml"; then
        echo -e "  ${GREEN}✓${NC} 包含 profile 属性定义"
    else
        echo -e "  ${RED}✗${NC} 缺少 profile 属性定义"
    fi
    
    if grep -q "<filtering>true</filtering>" "pom.xml"; then
        echo -e "  ${GREEN}✓${NC} 启用了资源文件过滤"
    else
        echo -e "  ${RED}✗${NC} 未启用资源文件过滤"
    fi
else
    echo -e "  ${RED}✗${NC} pom.xml 缺失"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  ✓ 配置文件验证完成!"
echo "==========================================${NC}"
echo ""
echo "下一步操作:"
echo "1. 编译项目: mvn clean package -Pdev|-Ptest|-Pprod"
echo "2. 启动服务: java -jar xxx.jar --spring.profiles.active=<env>"
echo "3. 查看详细文档: cat MULTI_ENV_GUIDE.md"
echo ""
