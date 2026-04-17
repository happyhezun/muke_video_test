#!/bin/bash

###############################################################################
# Jenkins 备份验证脚本
# 功能: 验证备份文件的完整性和有效性
# 用法: ./verify-backup.sh [backup-file.tar.gz]
###############################################################################

set -euo pipefail

BACKUP_BASE_DIR="/backup/jenkins"
LOG_FILE="${BACKUP_BASE_DIR}/logs/verify.log"

log() {
    local level=$1
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

# 验证单个备份文件
verify_backup() {
    local backup_file=$1
    local errors=0
    
    log "INFO" "=========================================="
    log "INFO" "验证备份: $(basename $backup_file)"
    log "INFO" "=========================================="
    
    # 1. 检查文件是否存在
    if [ ! -f "$backup_file" ]; then
        log "ERROR" "❌ 备份文件不存在: $backup_file"
        return 1
    fi
    log "INFO" "✅ 文件存在"
    
    # 2. 检查文件格式
    if ! file "$backup_file" | grep -q "gzip"; then
        log "ERROR" "❌ 不是有效的 gzip 文件"
        return 1
    fi
    log "INFO" "✅ 文件格式正确"
    
    # 3. 检查文件完整性
    if tar -tzf "$backup_file" > /dev/null 2>&1; then
        log "INFO" "✅ 备份文件完整,无损坏"
    else
        log "ERROR" "❌ 备份文件损坏或不完整"
        return 1
    fi
    
    # 4. 检查关键文件
    local key_files=("config.xml" "secret.key")
    for file in "${key_files[@]}"; do
        if tar -tzf "$backup_file" | grep -q "$file"; then
            log "INFO" "✅ 找到关键文件: $file"
        else
            log "WARN" "⚠️  缺少关键文件: $file"
            errors=$((errors + 1))
        fi
    done
    
    # 5. 检查备份大小
    local size=$(du -sh "$backup_file" | cut -f1)
    local size_bytes=$(stat -c%s "$backup_file")
    
    if [ "$size_bytes" -gt 10485760 ]; then  # 大于 10MB
        log "INFO" "✅ 备份大小合理: $size"
    else
        log "WARN" "⚠️  备份文件可能过小: $size"
        errors=$((errors + 1))
    fi
    
    # 6. 检查备份年龄
    local age_hours=$(( ($(date +%s) - $(stat -c %Y "$backup_file")) / 3600 ))
    if [ $age_hours -lt 48 ]; then
        log "INFO" "✅ 备份新鲜度: ${age_hours}小时前"
    elif [ $age_hours -lt 168 ]; then  # 7天
        log "WARN" "⚠️  备份已超过 48 小时 (${age_hours}小时前)"
    else
        log "ERROR" "❌ 备份过旧: ${age_hours}小时前"
        errors=$((errors + 1))
    fi
    
    # 7. 统计文件数量
    local file_count=$(tar -tzf "$backup_file" | wc -l)
    log "INFO" "📊 备份包含 ${file_count} 个文件"
    
    # 8. 显示目录结构(前20行)
    log "INFO" "📁 备份内容预览:"
    tar -tzf "$backup_file" | head -20 | while read line; do
        log "INFO" "   $line"
    done
    
    # 总结
    echo ""
    if [ $errors -eq 0 ]; then
        log "INFO" "=========================================="
        log "INFO" "✅ 备份验证通过!"
        log "INFO" "=========================================="
        return 0
    else
        log "WARN" "=========================================="
        log "WARN" "⚠️  备份验证发现 ${errors} 个问题"
        log "WARN" "=========================================="
        return 1
    fi
}

# 验证最新备份
verify_latest() {
    local latest=$(find "${BACKUP_BASE_DIR}/daily" -name "*.tar.gz" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [ -z "$latest" ]; then
        log "ERROR" "未找到任何备份文件"
        exit 1
    fi
    
    verify_backup "$latest"
}

# 验证所有最近的备份
verify_all() {
    local errors=0
    local count=0
    
    log "INFO" "开始验证所有 daily 备份..."
    echo ""
    
    for backup in "${BACKUP_BASE_DIR}/daily/"*.tar.gz; do
        if [ -f "$backup" ]; then
            if verify_backup "$backup"; then
                count=$((count + 1))
            else
                errors=$((errors + 1))
            fi
            echo ""
        fi
    done
    
    log "INFO" "=========================================="
    log "INFO" "验证完成: 成功 ${count}, 失败 ${errors}"
    log "INFO" "=========================================="
    
    return $errors
}

# 生成验证报告
generate_report() {
    local backup_file=$1
    
    cat > "${BACKUP_BASE_DIR}/latest-verify-report.txt" <<EOF
Jenkins 备份验证报告
====================

验证时间: $(date '+%Y-%m-%d %H:%M:%S')
备份文件: ${backup_file}
文件大小: $(du -sh "${backup_file}" | cut -f1)
文件年龄: $(( ($(date +%s) - $(stat -c %Y "${backup_file}")) / 3600 )) 小时前

完整性检查: $(tar -tzf "${backup_file}" > /dev/null 2>&1 && echo "PASS" || echo "FAIL")
关键文件检查: PASS
大小检查: PASS

状态: SUCCESS
EOF
    
    log "INFO" "验证报告已生成: ${BACKUP_BASE_DIR}/latest-verify-report.txt"
}

# 主函数
main() {
    mkdir -p "${BACKUP_BASE_DIR}/logs"
    
    if [ $# -eq 0 ]; then
        # 无参数,验证最新备份
        verify_latest
        generate_report "$(find "${BACKUP_BASE_DIR}/daily" -name "*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)"
    elif [ "$1" = "--all" ]; then
        # 验证所有备份
        verify_all
    elif [ "$1" = "--help" ]; then
        echo "用法: $0 [backup-file.tar.gz|--all|--help]"
        echo ""
        echo "选项:"
        echo "  backup-file    指定备份文件路径"
        echo "  --all          验证所有 daily 备份"
        echo "  --help         显示此帮助信息"
        echo ""
        echo "示例:"
        echo "  $0                                    # 验证最新备份"
        echo "  $0 /backup/jenkins/daily/xxx.tar.gz  # 验证指定备份"
        echo "  $0 --all                              # 验证所有备份"
    else
        # 验证指定备份
        verify_backup "$1"
        generate_report "$1"
    fi
}

main "$@"
