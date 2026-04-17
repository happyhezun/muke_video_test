#!/bin/bash

###############################################################################
# Jenkins 插件下载问题快速修复脚本
# 功能: 一键配置国内镜像源,解决插件下载失败问题
# 用法: ./fix-jenkins-plugins.sh
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "=========================================="
echo "  Jenkins 插件下载问题快速修复工具"
echo "=========================================="
echo ""

# 检查 Docker 是否运行
if ! docker ps > /dev/null 2>&1; then
    log_error "Docker 未运行,请先启动 Docker"
    exit 1
fi

# 检查 Jenkins 容器是否运行
if ! docker ps | grep -q jenkins; then
    log_error "Jenkins 容器未运行"
    echo "可用容器:"
    docker ps -a | grep jenkins || echo "未找到 Jenkins 容器"
    exit 1
fi

log_info "检测到 Jenkins 容器正在运行"
echo ""

# 选择镜像源
echo "请选择镜像源:"
echo "  1) 清华大学镜像 (推荐,速度最快)"
echo "  2) 华为云镜像 (稳定可靠)"
echo "  3) 阿里云镜像 (备选方案)"
echo ""
read -p "请输入选项 (1-3,默认 1): " choice

case $choice in
    2)
        MIRROR="https://mirrors.huaweicloud.com/jenkins"
        MIRROR_NAME="华为云"
        ;;
    3)
        MIRROR="https://mirrors.aliyun.com/jenkins"
        MIRROR_NAME="阿里云"
        ;;
    *)
        MIRROR="https://mirrors.tuna.tsinghua.edu.cn/jenkins"
        MIRROR_NAME="清华大学"
        ;;
esac

echo ""
log_info "已选择: ${MIRROR_NAME} 镜像"
log_info "镜像地址: ${MIRROR}"
echo ""

# 确认操作
read -p "是否继续配置? (y/n,默认 y): " confirm
if [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
    log_warn "操作已取消"
    exit 0
fi

echo ""
log_step "开始配置..."

# 步骤 1: 备份当前配置
log_step "步骤 1/4: 备份当前配置"
BACKUP_FILE="hudson.model.UpdateCenter.xml.bak.$(date +%Y%m%d_%H%M%S)"
docker exec jenkins bash -c "cd /var/jenkins_home && cp -f hudson.model.UpdateCenter.xml ${BACKUP_FILE}" 2>/dev/null || true
log_info "配置已备份到: ${BACKUP_FILE}"
echo ""

# 步骤 2: 修改更新中心地址
log_step "步骤 2/4: 修改更新中心地址"
docker exec jenkins bash -c "
cd /var/jenkins_home
sed -i 's|https://updates.jenkins.io/update-center.json|${MIRROR}/updates/update-center.json|g' hudson.model.UpdateCenter.xml
sed -i 's|http://updates.jenkins.io/update-center.json|${MIRROR}/updates/update-center.json|g' hudson.model.UpdateCenter.xml
"
log_info "更新中心地址已修改"
echo ""

# 步骤 3: 修改下载地址
log_step "步骤 3/4: 修改插件下载地址"
docker exec jenkins bash -c "
cd /var/jenkins_home
sed -i 's|https://updates.jenkins.io/download/|${MIRROR}/|g' hudson.model.UpdateCenter.xml
sed -i 's|http://updates.jenkins.io/download/|${MIRROR}/|g' hudson.model.UpdateCenter.xml
"
log_info "下载地址已修改"
echo ""

# 步骤 4: 验证配置
log_step "步骤 4/4: 验证配置"
UPDATE_URL=$(docker exec jenkins grep -o '<url>[^<]*</url>' /var/jenkins_home/hudson.model.UpdateCenter.xml | head -1 | sed 's/<url>//;s/<\/url>//')

if echo "$UPDATE_URL" | grep -q "tuna\|huaweicloud\|aliyun"; then
    log_info "✅ 配置验证成功"
    log_info "   更新中心: ${UPDATE_URL}"
else
    log_warn "⚠️  配置可能未正确应用"
    log_warn "   当前 URL: ${UPDATE_URL}"
fi
echo ""

# 重启 Jenkins
echo "=========================================="
log_info "配置完成,需要重启 Jenkins 使配置生效"
echo "=========================================="
echo ""
read -p "是否立即重启 Jenkins? (y/n,默认 y): " restart_confirm

if [ "$restart_confirm" != "n" ] && [ "$restart_confirm" != "N" ]; then
    log_step "正在重启 Jenkins..."
    docker restart jenkins
    
    echo ""
    log_info "Jenkins 正在重启..."
    log_info "请等待 1-2 分钟让服务完全启动"
    echo ""
    log_info "监控启动状态:"
    log_info "  docker logs -f jenkins"
    echo ""
    log_info "访问地址:"
    log_info "  http://localhost:6080"
    echo ""
    
    # 等待 Jenkins 启动
    echo "等待 Jenkins 启动..."
    for i in {1..60}; do
        if docker exec jenkins curl -s http://localhost:8080/login > /dev/null 2>&1; then
            log_info "✅ Jenkins 已启动!"
            break
        fi
        echo -n "."
        sleep 2
    done
    echo ""
else
    log_info "请稍后手动重启 Jenkins:"
    log_info "  docker restart jenkins"
fi

echo ""
echo "=========================================="
echo "  配置总结"
echo "=========================================="
echo ""
echo "镜像源: ${MIRROR_NAME}"
echo "地址: ${MIRROR}"
echo ""
echo "下一步操作:"
echo "  1. 访问 http://localhost:6080"
echo "  2. 进入: 系统管理 → 插件管理 → 高级"
echo "  3. 确认更新站点 URL 已更改"
echo "  4. 点击 '立即获取' 测试连接"
echo ""
echo "如需恢复原配置,执行:"
echo "  docker exec jenkins bash -c 'cd /var/jenkins_home && mv ${BACKUP_FILE} hudson.model.UpdateCenter.xml'"
echo "  docker restart jenkins"
echo ""
log_info "完成! 🎉"
echo ""
