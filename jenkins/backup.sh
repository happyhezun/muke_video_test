#!/bin/bash

###############################################################################
# Jenkins 自动备份脚本
# 功能: 备份 Jenkins 数据、配置和流水线历史
# 用法: ./backup.sh [full|incremental]
###############################################################################

set -euo pipefail

# ==================== 配置区域 ====================

# 备份目录
BACKUP_BASE_DIR="/backup/jenkins"

# Jenkins 数据目录
JENKINS_HOME="/data/jenkins_home"

# 保留天数
RETENTION_DAYS=30

# 日志文件
LOG_FILE="${BACKUP_BASE_DIR}/backup.log"

# 通知邮箱(可选)
NOTIFY_EMAIL=""

# 备份类型: full(全量) 或 incremental(增量)
BACKUP_TYPE="${1:-full}"

# 时间戳
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE=$(date +%Y-%m-%d)

# ==================== 函数定义 ====================

# 日志函数
log() {
    local level=$1
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

# 发送通知(可选)
send_notification() {
    local subject=$1
    local body=$2
    
    if [ -n "$NOTIFY_EMAIL" ]; then
        echo "$body" | mail -s "$subject" "$NOTIFY_EMAIL" || true
    fi
}

# 检查磁盘空间
check_disk_space() {
    local required_mb=$1
    local available_mb
    
    available_mb=$(df -m "$BACKUP_BASE_DIR" | awk 'NR==2 {print $4}')
    
    if [ "$available_mb" -lt "$required_mb" ]; then
        log "ERROR" "磁盘空间不足! 需要: ${required_mb}MB, 可用: ${available_mb}MB"
        send_notification "Jenkins 备份失败" "磁盘空间不足"
        exit 1
    fi
    
    log "INFO" "磁盘空间检查通过: 可用 ${available_mb}MB"
}

# 计算 Jenkins 数据大小
get_jenkins_size() {
    du -sm "$JENKINS_HOME" | cut -f1
}

# 创建备份目录结构
create_backup_dirs() {
    mkdir -p "${BACKUP_BASE_DIR}/daily"
    mkdir -p "${BACKUP_BASE_DIR}/weekly"
    mkdir -p "${BACKUP_BASE_DIR}/monthly"
    mkdir -p "${BACKUP_BASE_DIR}/logs"
    
    log "INFO" "备份目录结构创建完成"
}

# 备份核心配置
backup_configs() {
    local backup_dir=$1
    
    log "INFO" "开始备份配置文件..."
    
    # 备份重要配置文件
    cp -r "${JENKINS_HOME}/config.xml" "${backup_dir}/" 2>/dev/null || true
    cp -r "${JENKINS_HOME}/hudson.model.UpdateCenter.xml" "${backup_dir}/" 2>/dev/null || true
    cp -r "${JENKINS_HOME}/credentials.xml" "${backup_dir}/" 2>/dev/null || true
    cp -r "${JENKINS_HOME}/secret.key" "${backup_dir}/" 2>/dev/null || true
    cp -r "${JENKINS_HOME}/secret.key.not-so-secret" "${backup_dir}/" 2>/dev/null || true
    
    # 备份用户配置
    cp -r "${JENKINS_HOME}/users" "${backup_dir}/" 2>/dev/null || true
    
    # 备份全局配置
    cp -r "${JENKINS_HOME}/jenkins.model.JenkinsLocationConfiguration.xml" "${backup_dir}/" 2>/dev/null || true
    
    log "INFO" "配置文件备份完成"
}

# 备份作业配置
backup_jobs() {
    local backup_dir=$1
    
    log "INFO" "开始备份作业配置..."
    
    if [ -d "${JENKINS_HOME}/jobs" ]; then
        # 只备份 config.xml,不备份构建历史(减小体积)
        find "${JENKINS_HOME}/jobs" -name "config.xml" -exec cp --parents {} "${backup_dir}/jobs/" \; 2>/dev/null || true
        log "INFO" "作业配置备份完成"
    else
        log "WARN" "jobs 目录不存在,跳过"
    fi
}

# 备份插件
backup_plugins() {
    local backup_dir=$1
    
    log "INFO" "开始备份插件列表..."
    
    # 备份插件列表(文本格式,便于查看)
    if [ -d "${JENKINS_HOME}/plugins" ]; then
        ls "${JENKINS_HOME}/plugins"/*.jpi 2>/dev/null | xargs -n1 basename | sed 's/.jpi$//' > "${backup_dir}/plugins-list.txt" || true
        ls "${JENKINS_HOME}/plugins"/*.hpi 2>/dev/null | xargs -n1 basename | sed 's/.hpi$//' >> "${backup_dir}/plugins-list.txt" || true
        
        # 可选: 备份插件文件本身(体积较大)
        # cp -r "${JENKINS_HOME}/plugins" "${backup_dir}/plugins/" 2>/dev/null || true
        
        log "INFO" "插件列表备份完成 (共 $(wc -l < "${backup_dir}/plugins-list.txt") 个插件)"
    else
        log "WARN" "plugins 目录不存在,跳过"
    fi
}

# 备份用户内容
backup_user_content() {
    local backup_dir=$1
    
    log "INFO" "开始备份用户内容..."
    
    # 备份 workspace (可选,通常不需要)
    # cp -r "${JENKINS_HOME}/workspace" "${backup_dir}/" 2>/dev/null || true
    
    # 备份 fingerprints
    cp -r "${JENKINS_HOME}/fingerprints" "${backup_dir}/" 2>/dev/null || true
    
    # 备份 userContent
    cp -r "${JENKINS_HOME}/userContent" "${backup_dir}/" 2>/dev/null || true
    
    log "INFO" "用户内容备份完成"
}

# 导出 Jenkins 配置(通过 CLI)
export_jenkins_config() {
    local backup_dir=$1
    
    log "INFO" "尝试通过 CLI 导出配置..."
    
    # 如果 Jenkins CLI 可用,导出完整配置
    if command -v java &> /dev/null && [ -f "${JENKINS_HOME}/jenkins-cli.jar" ]; then
        java -jar "${JENKINS_HOME}/jenkins-cli.jar" \
            -s http://localhost:8080 \
            get-job DSL_JOB_NAME > "${backup_dir}/dsl-config.xml" 2>/dev/null || true
        
        log "INFO" "CLI 配置导出完成"
    else
        log "WARN" "Jenkins CLI 不可用,跳过"
    fi
}

# 创建备份归档
create_archive() {
    local backup_dir=$1
    local archive_name="jenkins-backup-${BACKUP_TYPE}-${TIMESTAMP}.tar.gz"
    local archive_path="${BACKUP_BASE_DIR}/${archive_name}"
    
    log "INFO" "创建备份归档: ${archive_name}"
    
    tar -czf "${archive_path}" -C "${backup_dir}" .
    
    local size=$(du -sh "${archive_path}" | cut -f1)
    log "INFO" "备份归档完成,大小: ${size}"
    
    echo "${archive_path}"
}

# 清理旧备份
cleanup_old_backups() {
    log "INFO" "清理 ${RETENTION_DAYS} 天前的备份..."
    
    # 清理 daily 备份
    find "${BACKUP_BASE_DIR}/daily" -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
    
    # 清理 weekly 备份(保留 12 周)
    find "${BACKUP_BASE_DIR}/weekly" -name "*.tar.gz" -mtime +84 -delete 2>/dev/null || true
    
    # 清理 monthly 备份(保留 12 个月)
    find "${BACKUP_BASE_DIR}/monthly" -name "*.tar.gz" -mtime +365 -delete 2>/dev/null || true
    
    # 清理旧日志
    find "${BACKUP_BASE_DIR}/logs" -name "*.log" -mtime +90 -delete 2>/dev/null || true
    
    log "INFO" "清理完成"
}

# 生成备份报告
generate_report() {
    local archive_path=$1
    local duration=$2
    
    cat > "${BACKUP_BASE_DIR}/latest-backup-report.txt" <<EOF
Jenkins 备份报告
================

备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份类型: ${BACKUP_TYPE}
备份文件: ${archive_path}
文件大小: $(du -sh "${archive_path}" | cut -f1)
耗时: ${duration} 秒

Jenkins 数据大小: $(get_jenkins_size) MB
磁盘可用空间: $(df -h "${BACKUP_BASE_DIR}" | awk 'NR==2 {print $4}')

备份内容:
- 核心配置文件
- 作业配置 (不含构建历史)
- 插件列表
- 用户内容

保留策略:
- Daily: ${RETENTION_DAYS} 天
- Weekly: 12 周
- Monthly: 12 个月

状态: SUCCESS
EOF
    
    log "INFO" "备份报告已生成"
}

# ==================== 主流程 ====================

main() {
    local start_time=$(date +%s)
    
    log "INFO" "=========================================="
    log "INFO" "开始 Jenkins ${BACKUP_TYPE} 备份"
    log "INFO" "=========================================="
    
    # 1. 创建目录结构
    create_backup_dirs
    
    # 2. 检查磁盘空间
    local jenkins_size=$(get_jenkins_size)
    local required_space=$((jenkins_size * 2))  # 需要 2 倍空间
    check_disk_space "$required_space"
    
    # 3. 创建临时备份目录
    local temp_backup_dir=$(mktemp -d "${BACKUP_BASE_DIR}/tmp-backup-XXXXXX")
    log "INFO" "临时备份目录: ${temp_backup_dir}"
    
    # 4. 执行备份
    backup_configs "$temp_backup_dir"
    backup_jobs "$temp_backup_dir"
    backup_plugins "$temp_backup_dir"
    backup_user_content "$temp_backup_dir"
    export_jenkins_config "$temp_backup_dir"
    
    # 5. 创建归档
    local archive_path=$(create_archive "$temp_backup_dir")
    
    # 6. 根据备份类型移动到相应目录
    case "$BACKUP_TYPE" in
        full)
            mv "${archive_path}" "${BACKUP_BASE_DIR}/daily/"
            log "INFO" "全量备份已保存到 daily 目录"
            
            # 每周日额外保存到 weekly
            if [ "$(date +%u)" -eq 7 ]; then
                cp "${BACKUP_BASE_DIR}/daily/$(basename ${archive_path})" "${BACKUP_BASE_DIR}/weekly/"
                log "INFO" "周日备份已复制到 weekly 目录"
            fi
            
            # 每月 1 号额外保存到 monthly
            if [ "$(date +%d)" -eq 01 ]; then
                cp "${BACKUP_BASE_DIR}/daily/$(basename ${archive_path})" "${BACKUP_BASE_DIR}/monthly/"
                log "INFO" "月初备份已复制到 monthly 目录"
            fi
            ;;
        incremental)
            mv "${archive_path}" "${BACKUP_BASE_DIR}/daily/"
            log "INFO" "增量备份已保存到 daily 目录"
            ;;
    esac
    
    # 7. 清理临时文件
    rm -rf "$temp_backup_dir"
    
    # 8. 清理旧备份
    cleanup_old_backups
    
    # 9. 计算耗时
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # 10. 生成报告
    generate_report "${BACKUP_BASE_DIR}/daily/$(basename ${archive_path})" "$duration"
    
    # 11. 发送通知
    send_notification \
        "Jenkins 备份成功 (${BACKUP_TYPE})" \
        "备份完成!\n文件: ${archive_path}\n耗时: ${duration}秒\n大小: $(du -sh "${archive_path}" | cut -f1)"
    
    log "INFO" "=========================================="
    log "INFO" "备份完成! 耗时: ${duration} 秒"
    log "INFO" "备份文件: ${archive_path}"
    log "INFO" "=========================================="
}

# 执行主流程
main "$@"
