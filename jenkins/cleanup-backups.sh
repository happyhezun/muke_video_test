#!/bin/bash

###############################################################################
# Jenkins 备份清理脚本
# 功能: 清理过期的备份文件,释放磁盘空间
# 用法: ./cleanup-backups.sh [--dry-run]
###############################################################################

set -euo pipefail

BACKUP_BASE_DIR="/backup/jenkins"
LOG_FILE="${BACKUP_BASE_DIR}/logs/cleanup.log"

# 保留策略
DAILY_RETENTION_DAYS=30
WEEKLY_RETENTION_DAYS=84    # 12 周
MONTHLY_RETENTION_DAYS=365  # 12 个月

# 磁盘使用率告警阈值(百分比)
DISK_USAGE_THRESHOLD=80

log() {
    local level=$1
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

# 显示使用说明
show_usage() {
    cat <<EOF
Jenkins 备份清理工具

用法:
    $0 [options]

选项:
    --dry-run          模拟清理,不实际删除
    --force            强制清理,不询问确认
    --stats            仅显示统计信息
    --help             显示此帮助信息

保留策略:
    Daily:   ${DAILY_RETENTION_DAYS} 天
    Weekly:  ${WEEKLY_RETENTION_DAYS} 天 (12 周)
    Monthly: ${MONTHLY_RETENTION_DAYS} 天 (12 个月)

示例:
    # 模拟清理
    $0 --dry-run
    
    # 执行清理
    $0
    
    # 查看统计
    $0 --stats

EOF
}

# 显示当前备份统计
show_stats() {
    echo ""
    echo "=========================================="
    echo "Jenkins 备份统计"
    echo "=========================================="
    echo ""
    
    # Daily backups
    local daily_count=$(find "${BACKUP_BASE_DIR}/daily" -name "*.tar.gz" -type f 2>/dev/null | wc -l)
    local daily_size=$(du -sh "${BACKUP_BASE_DIR}/daily" 2>/dev/null | cut -f1 || echo "0")
    echo "📅 Daily Backups:"
    echo "   数量: ${daily_count}"
    echo "   大小: ${daily_size}"
    if [ $daily_count -gt 0 ]; then
        echo "   最早: $(ls -t "${BACKUP_BASE_DIR}/daily/"*.tar.gz 2>/dev/null | tail -1 | xargs basename 2>/dev/null || echo "N/A")"
        echo "   最新: $(ls -t "${BACKUP_BASE_DIR}/daily/"*.tar.gz 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "N/A")"
    fi
    echo ""
    
    # Weekly backups
    local weekly_count=$(find "${BACKUP_BASE_DIR}/weekly" -name "*.tar.gz" -type f 2>/dev/null | wc -l)
    local weekly_size=$(du -sh "${BACKUP_BASE_DIR}/weekly" 2>/dev/null | cut -f1 || echo "0")
    echo "📆 Weekly Backups:"
    echo "   数量: ${weekly_count}"
    echo "   大小: ${weekly_size}"
    echo ""
    
    # Monthly backups
    local monthly_count=$(find "${BACKUP_BASE_DIR}/monthly" -name "*.tar.gz" -type f 2>/dev/null | wc -l)
    local monthly_size=$(du -sh "${BACKUP_BASE_DIR}/monthly" 2>/dev/null | cut -f1 || echo "0")
    echo "🗓️  Monthly Backups:"
    echo "   数量: ${monthly_count}"
    echo "   大小: ${monthly_size}"
    echo ""
    
    # Total
    local total_size=$(du -sh "${BACKUP_BASE_DIR}" 2>/dev/null | cut -f1 || echo "0")
    echo "💾 Total Backup Size: ${total_size}"
    echo ""
    
    # Disk usage
    local disk_usage=$(df -h "${BACKUP_BASE_DIR}" | awk 'NR==2 {print $5}')
    local disk_available=$(df -h "${BACKUP_BASE_DIR}" | awk 'NR==2 {print $4}')
    echo "💿 Disk Usage: ${disk_usage} (Available: ${disk_available})"
    echo ""
    echo "=========================================="
}

# 检查磁盘使用率
check_disk_usage() {
    local usage=$(df "${BACKUP_BASE_DIR}" | awk 'NR==2 {print $5}' | sed 's/%//')
    
    log "INFO" "当前磁盘使用率: ${usage}%"
    
    if [ "$usage" -gt "$DISK_USAGE_THRESHOLD" ]; then
        log "WARN" "⚠️  磁盘使用率超过阈值 (${DISK_USAGE_THRESHOLD}%)"
        return 1
    else
        log "INFO" "✅ 磁盘使用率正常"
        return 0
    fi
}

# 清理过期备份
cleanup_backups() {
    local dry_run=$1
    local deleted_count=0
    local freed_space=0
    
    log "INFO" "开始清理过期备份..."
    log "INFO" "保留策略: Daily=${DAILY_RETENTION_DAYS}天, Weekly=${WEEKLY_RETENTION_DAYS}天, Monthly=${MONTHLY_RETENTION_DAYS}天"
    echo ""
    
    # 清理 daily 备份
    log "INFO" "清理 ${DAILY_RETENTION_DAYS} 天前的 daily 备份..."
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            local size=$(stat -c%s "$file" 2>/dev/null || echo 0)
            if [ "$dry_run" = true ]; then
                log "INFO" "[DRY RUN] 将删除: $(basename $file) ($(du -sh "$file" | cut -f1))"
            else
                rm -f "$file"
                log "INFO" "已删除: $(basename $file)"
            fi
            deleted_count=$((deleted_count + 1))
            freed_space=$((freed_space + size))
        fi
    done < <(find "${BACKUP_BASE_DIR}/daily" -name "*.tar.gz" -type f -mtime +${DAILY_RETENTION_DAYS} 2>/dev/null)
    
    # 清理 weekly 备份
    log "INFO" "清理 ${WEEKLY_RETENTION_DAYS} 天前的 weekly 备份..."
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            local size=$(stat -c%s "$file" 2>/dev/null || echo 0)
            if [ "$dry_run" = true ]; then
                log "INFO" "[DRY RUN] 将删除: $(basename $file) ($(du -sh "$file" | cut -f1))"
            else
                rm -f "$file"
                log "INFO" "已删除: $(basename $file)"
            fi
            deleted_count=$((deleted_count + 1))
            freed_space=$((freed_space + size))
        fi
    done < <(find "${BACKUP_BASE_DIR}/weekly" -name "*.tar.gz" -type f -mtime +${WEEKLY_RETENTION_DAYS} 2>/dev/null)
    
    # 清理 monthly 备份
    log "INFO" "清理 ${MONTHLY_RETENTION_DAYS} 天前的 monthly 备份..."
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            local size=$(stat -c%s "$file" 2>/dev/null || echo 0)
            if [ "$dry_run" = true ]; then
                log "INFO" "[DRY RUN] 将删除: $(basename $file) ($(du -sh "$file" | cut -f1))"
            else
                rm -f "$file"
                log "INFO" "已删除: $(basename $file)"
            fi
            deleted_count=$((deleted_count + 1))
            freed_space=$((freed_space + size))
        fi
    done < <(find "${BACKUP_BASE_DIR}/monthly" -name "*.tar.gz" -type f -mtime +${MONTHLY_RETENTION_DAYS} 2>/dev/null)
    
    # 清理旧日志(90天)
    log "INFO" "清理 90 天前的日志文件..."
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            if [ "$dry_run" = true ]; then
                log "INFO" "[DRY RUN] 将删除日志: $(basename $file)"
            else
                rm -f "$file"
                log "INFO" "已删除日志: $(basename $file)"
            fi
        fi
    done < <(find "${BACKUP_BASE_DIR}/logs" -name "*.log" -type f -mtime +90 2>/dev/null)
    
    echo ""
    log "INFO" "=========================================="
    log "INFO" "清理完成!"
    log "INFO" "删除文件数: ${deleted_count}"
    log "INFO" "释放空间: $(numfmt --to=iec ${freed_space})"
    log "INFO" "=========================================="
}

# 主函数
main() {
    local dry_run=false
    local force=false
    local stats_only=false
    
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
            --stats)
                stats_only=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log "ERROR" "未知参数: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    mkdir -p "${BACKUP_BASE_DIR}/logs"
    
    # 显示统计
    show_stats
    
    if [ "$stats_only" = true ]; then
        exit 0
    fi
    
    # 检查磁盘使用
    check_disk_usage || true
    
    # 确认操作
    if [ "$force" = false ] && [ "$dry_run" = false ]; then
        echo ""
        echo "⚠️  警告: 此操作将删除过期的备份文件!"
        echo ""
        read -p "是否继续? (yes/no): " confirm
        
        if [ "$confirm" != "yes" ]; then
            log "INFO" "用户取消操作"
            exit 0
        fi
    fi
    
    # 执行清理
    cleanup_backups "$dry_run"
    
    # 再次显示统计
    echo ""
    show_stats
}

main "$@"


