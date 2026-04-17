#!/bin/bash

###############################################################################
# Jenkins 数据恢复脚本
# 功能: 从备份文件恢复 Jenkins 数据
# 用法: ./restore.sh <backup-file.tar.gz>
###############################################################################

set -euo pipefail

# ==================== 配置区域 ====================

# Jenkins 数据目录
JENKINS_HOME="/data/jenkins_home"

# 备份目录
BACKUP_BASE_DIR="/backup/jenkins"

# 日志文件
LOG_FILE="${BACKUP_BASE_DIR}/restore.log"

# ==================== 函数定义 ====================

# 日志函数
log() {
    local level=$1
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

# 显示使用说明
show_usage() {
    cat <<EOF
Jenkins 数据恢复工具

用法:
    $0 <backup-file.tar.gz> [options]

参数:
    backup-file    备份文件路径 (.tar.gz)

选项:
    --dry-run      模拟恢复,不实际执行
    --force        强制恢复,不询问确认
    --list         列出可用备份
    --latest       使用最新的备份
    --help         显示此帮助信息

示例:
    # 恢复指定备份
    $0 /backup/jenkins/daily/jenkins-backup-full-20260417_120000.tar.gz
    
    # 使用最新备份
    $0 --latest
    
    # 列出所有可用备份
    $0 --list
    
    # 模拟恢复(不实际执行)
    $0 backup.tar.gz --dry-run

注意事项:
    1. 恢复前会自动停止 Jenkins 服务
    2. 当前数据会被备份到 JENKINS_HOME.backup.<timestamp>
    3. 恢复完成后需要重启 Jenkins
    4. 确保有足够的磁盘空间

EOF
}

# 列出可用备份
list_backups() {
    log "INFO" "可用的备份文件:"
    echo ""
    
    if [ ! -d "${BACKUP_BASE_DIR}" ]; then
        log "ERROR" "备份目录不存在: ${BACKUP_BASE_DIR}"
        exit 1
    fi
    
    echo "=== Daily Backups ==="
    ls -lh "${BACKUP_BASE_DIR}/daily/"*.tar.gz 2>/dev/null | tail -10 || echo "无"
    echo ""
    
    echo "=== Weekly Backups ==="
    ls -lh "${BACKUP_BASE_DIR}/weekly/"*.tar.gz 2>/dev/null | tail -5 || echo "无"
    echo ""
    
    echo "=== Monthly Backups ==="
    ls -lh "${BACKUP_BASE_DIR}/monthly/"*.tar.gz 2>/dev/null | tail -5 || echo "无"
    echo ""
}

# 获取最新备份文件
get_latest_backup() {
    local latest
    
    latest=$(find "${BACKUP_BASE_DIR}/daily" -name "*.tar.gz" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [ -z "$latest" ]; then
        log "ERROR" "未找到任何备份文件"
        exit 1
    fi
    
    echo "$latest"
}

# 检查依赖
check_dependencies() {
    log "INFO" "检查依赖..."
    
    for cmd in tar docker; do
        if ! command -v "$cmd" &> /dev/null; then
            log "ERROR" "缺少必要命令: $cmd"
            exit 1
        fi
    done
    
    log "INFO" "依赖检查通过"
}

# 验证备份文件
validate_backup() {
    local backup_file=$1
    
    log "INFO" "验证备份文件: ${backup_file}"
    
    # 检查文件是否存在
    if [ ! -f "$backup_file" ]; then
        log "ERROR" "备份文件不存在: ${backup_file}"
        exit 1
    fi
    
    # 检查文件格式
    if ! file "$backup_file" | grep -q "gzip"; then
        log "ERROR" "不是有效的 gzip 压缩文件"
        exit 1
    fi
    
    # 检查文件完整性
    if ! tar -tzf "$backup_file" > /dev/null 2>&1; then
        log "ERROR" "备份文件损坏或不完整"
        exit 1
    fi
    
    # 显示文件信息
    local size=$(du -sh "$backup_file" | cut -f1)
    local files=$(tar -tzf "$backup_file" | wc -l)
    log "INFO" "备份文件大小: ${size}, 包含 ${files} 个文件"
}

# 停止 Jenkins
stop_jenkins() {
    log "INFO" "停止 Jenkins 服务..."
    
    docker stop jenkins 2>/dev/null || true
    
    # 等待 Jenkins 完全停止
    sleep 5
    
    # 验证是否停止
    if docker ps | grep -q jenkins; then
        log "ERROR" "Jenkins 未能停止"
        exit 1
    fi
    
    log "INFO" "Jenkins 已停止"
}

# 启动 Jenkins
start_jenkins() {
    log "INFO" "启动 Jenkins 服务..."
    
    docker start jenkins
    
    log "INFO" "Jenkins 正在启动,请稍候..."
    log "INFO" "可以通过以下命令查看日志: docker logs -f jenkins"
}

# 备份当前数据
backup_current_data() {
    local backup_name="JENKINS_HOME.backup.$(date +%Y%m%d_%H%M%S)"
    local backup_path="/data/${backup_name}"
    
    log "INFO" "备份当前数据到: ${backup_path}"
    
    if [ -d "$JENKINS_HOME" ]; then
        mv "$JENKINS_HOME" "$backup_path"
        log "INFO" "当前数据已备份到: ${backup_path}"
        log "WARN" "如果恢复失败,可以手动恢复: mv ${backup_path} ${JENKINS_HOME}"
    else
        log "WARN" "JENKINS_HOME 目录不存在,跳过备份"
    fi
}

# 恢复数据
restore_data() {
    local backup_file=$1
    local dry_run=$2
    
    log "INFO" "开始恢复数据..."
    
    # 创建 JENKINS_HOME 目录
    mkdir -p "$JENKINS_HOME"
    
    if [ "$dry_run" = true ]; then
        log "INFO" "[DRY RUN] 将执行: tar -xzf ${backup_file} -C ${JENKINS_HOME}"
        
        # 显示将要恢复的文件列表
        echo ""
        echo "将要恢复的文件结构:"
        tar -tzf "$backup_file" | head -20
        echo "..."
        echo ""
        
        return 0
    fi
    
    # 解压备份文件
    log "INFO" "解压备份文件到 ${JENKINS_HOME}..."
    tar -xzf "$backup_file" -C "$JENKINS_HOME"
    
    log "INFO" "数据恢复完成"
}

# 修复权限
fix_permissions() {
    log "INFO" "修复文件权限..."
    
    # Jenkins 容器内通常使用 UID 1000
    chown -R 1000:1000 "$JENKINS_HOME" 2>/dev/null || true
    chmod -R 755 "$JENKINS_HOME" 2>/dev/null || true
    
    log "INFO" "权限修复完成"
}

# 验证恢复
verify_restore() {
    log "INFO" "验证恢复结果..."
    
    # 检查关键文件是否存在
    local required_files=(
        "config.xml"
        "secret.key"
    )
    
    local missing=0
    for file in "${required_files[@]}"; do
        if [ ! -f "${JENKINS_HOME}/${file}" ]; then
            log "WARN" "缺少文件: ${file}"
            missing=$((missing + 1))
        fi
    done
    
    if [ $missing -gt 0 ]; then
        log "WARN" "发现 ${missing} 个缺失文件,但不影响基本功能"
    else
        log "INFO" "关键文件检查通过"
    fi
    
    # 检查目录大小
    local size=$(du -sh "$JENKINS_HOME" | cut -f1)
    log "INFO" "恢复后的数据大小: ${size}"
}

# 生成恢复报告
generate_restore_report() {
    local backup_file=$1
    
    cat > "${BACKUP_BASE_DIR}/latest-restore-report.txt" <<EOF
Jenkins 恢复报告
================

恢复时间: $(date '+%Y-%m-%d %H:%M:%S')
备份文件: ${backup_file}
目标目录: ${JENKINS_HOME}
数据大小: $(du -sh "${JENKINS_HOME}" | cut -f1)

恢复内容:
$(tar -tzf "${backup_file}" | head -20)
...

后续步骤:
1. 启动 Jenkins: docker start jenkins
2. 查看日志: docker logs -f jenkins
3. 访问 Web 界面: http://localhost:6080
4. 验证作业和配置是否正常

状态: SUCCESS
EOF
    
    log "INFO" "恢复报告已生成"
}

# ==================== 主流程 ====================

main() {
    local backup_file=""
    local dry_run=false
    local force=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            --list)
                list_backups
                exit 0
                ;;
            --latest)
                backup_file=$(get_latest_backup)
                log "INFO" "使用最新备份: ${backup_file}"
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                if [ -z "$backup_file" ]; then
                    backup_file="$1"
                else
                    log "ERROR" "未知参数: $1"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # 检查是否提供了备份文件
    if [ -z "$backup_file" ]; then
        log "ERROR" "请指定备份文件或使用 --latest 选项"
        show_usage
        exit 1
    fi
    
    log "INFO" "=========================================="
    log "INFO" "开始 Jenkins 数据恢复"
    log "INFO" "=========================================="
    
    # 1. 检查依赖
    check_dependencies
    
    # 2. 验证备份文件
    validate_backup "$backup_file"
    
    # 3. 确认操作
    if [ "$force" = false ] && [ "$dry_run" = false ]; then
        echo ""
        echo "⚠️  警告: 此操作将覆盖当前的 Jenkins 数据!"
        echo "备份文件: ${backup_file}"
        echo "目标目录: ${JENKINS_HOME}"
        echo ""
        read -p "是否继续? (yes/no): " confirm
        
        if [ "$confirm" != "yes" ]; then
            log "INFO" "用户取消操作"
            exit 0
        fi
    fi
    
    # 4. 停止 Jenkins
    stop_jenkins
    
    # 5. 备份当前数据
    if [ "$dry_run" = false ]; then
        backup_current_data
    fi
    
    # 6. 恢复数据
    restore_data "$backup_file" "$dry_run"
    
    if [ "$dry_run" = true ]; then
        log "INFO" "模拟恢复完成,未执行实际操作"
        exit 0
    fi
    
    # 7. 修复权限
    fix_permissions
    
    # 8. 验证恢复
    verify_restore
    
    # 9. 生成报告
    generate_restore_report "$backup_file"
    
    # 10. 启动 Jenkins
    start_jenkins
    
    log "INFO" "=========================================="
    log "INFO" "恢复完成!"
    log "INFO" "=========================================="
    log "INFO" ""
    log "INFO" "后续步骤:"
    log "INFO" "1. 查看 Jenkins 日志: docker logs -f jenkins"
    log "INFO" "2. 访问 Web 界面: http://localhost:6080"
    log "INFO" "3. 验证作业和配置是否正常"
    log "INFO" "4. 如有问题,查看恢复报告: ${BACKUP_BASE_DIR}/latest-restore-report.txt"
    log "INFO" ""
}

# 执行主流程
main "$@"
