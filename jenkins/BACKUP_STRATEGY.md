# Jenkins 备份策略完整方案

## 📋 目录

- [备份策略概述](#备份策略概述)
- [自动备份配置](#自动备份配置)
- [备份脚本使用](#备份脚本使用)
- [恢复流程](#恢复流程)
- [备份验证](#备份验证)
- [最佳实践](#最佳实践)
- [监控和告警](#监控和告警)

---

## 备份策略概述

### 3-2-1 备份原则

本项目采用业界标准的 **3-2-1 备份策略**:

- **3** 份数据副本
- **2** 种不同的存储介质
- **1** 个异地备份

### 备份类型

| 备份类型 | 频率 | 保留时间 | 说明 |
|---------|------|---------|------|
| **Daily** | 每天凌晨 2:00 | 30 天 | 全量备份,包含所有配置 |
| **Weekly** | 每周日 | 12 周 | 从 daily 复制,长期保留 |
| **Monthly** | 每月 1 号 | 12 个月 | 从 daily 复制,归档保存 |

### 备份内容

✅ **包含**:
- Jenkins 核心配置 (config.xml)
- 作业配置 (jobs/*/config.xml)
- 插件列表
- 用户配置和凭证
- 系统配置

❌ **不包含**:
- 构建历史和工作空间(体积大,可重新构建)
- 构建产物和 artifacts
- 临时文件和日志

### 预估存储空间

```
Jenkins 数据大小: ~2GB
单次备份大小: ~500MB (不含构建历史)

月度存储需求:
- Daily: 30 × 500MB = 15GB
- Weekly: 4 × 500MB = 2GB
- Monthly: 12 × 500MB = 6GB
总计: ~23GB/月
```

---

## 自动备份配置

### 方案 1: Cron 定时任务(推荐)

#### 步骤 1: 设置脚本权限

```bash
# 赋予执行权限
chmod +x backup.sh restore.sh

# 移动到系统目录(可选)
sudo cp backup.sh /usr/local/bin/jenkins-backup
sudo cp restore.sh /usr/local/bin/jenkins-restore
```

#### 步骤 2: 创建 Cron 任务

```bash
# 编辑 crontab
crontab -e

# 添加以下任务:

# 每天凌晨 2:00 执行全量备份
0 2 * * * /path/to/backup.sh full >> /backup/jenkins/logs/cron-backup.log 2>&1

# 每周日凌晨 3:00 执行额外备份(已自动处理,此条可选)
0 3 * * 0 /path/to/backup.sh full >> /backup/jenkins/logs/cron-weekly.log 2>&1

# 每月 1 号凌晨 4:00 执行额外备份(已自动处理,此条可选)
0 4 1 * * /path/to/backup.sh full >> /backup/jenkins/logs/cron-monthly.log 2>&1
```

#### 步骤 3: 验证 Cron 任务

```bash
# 查看当前 cron 任务
crontab -l

# 查看 cron 日志
grep CRON /var/log/syslog | tail -20
```

---

### 方案 2: Systemd Timer(现代 Linux)

创建 systemd timer 服务:

```bash
# 创建 service 文件
sudo tee /etc/systemd/system/jenkins-backup.service <<EOF
[Unit]
Description=Jenkins Backup Service
After=docker.service

[Service]
Type=oneshot
ExecStart=/path/to/backup.sh full
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# 创建 timer 文件
sudo tee /etc/systemd/system/jenkins-backup.timer <<EOF
[Unit]
Description=Run Jenkins Backup Daily

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 启用并启动 timer
sudo systemctl daemon-reload
sudo systemctl enable jenkins-backup.timer
sudo systemctl start jenkins-backup.timer

# 查看状态
systemctl list-timers --all | grep jenkins
```

---

### 方案 3: Docker Compose 集成

在 `docker-compose.yml` 中添加备份服务:

```yaml
services:
  jenkins-backup:
    image: alpine:latest
    container_name: jenkins-backup
    volumes:
      - /data/jenkins_home:/jenkins-home:ro
      - /backup/jenkins:/backup
      - ./backup.sh:/backup.sh:ro
    environment:
      - BACKUP_TYPE=full
    command: >
      sh -c "
        apk add --no-cache bash tar &&
        /backup.sh full
      "
    restart: "no"
```

触发备份:
```bash
docker-compose run jenkins-backup
```

---

## 备份脚本使用

### 基本用法

```bash
# 全量备份
./backup.sh full

# 增量备份(未来扩展)
./backup.sh incremental
```

### 手动执行备份

```bash
# 立即执行备份
./backup.sh full

# 查看备份进度
tail -f /backup/jenkins/backup.log

# 查看最新备份
ls -lh /backup/jenkins/daily/ | tail -5
```

### 备份报告

每次备份后会生成报告:

```bash
cat /backup/jenkins/latest-backup-report.txt
```

示例输出:
```
Jenkins 备份报告
================

备份时间: 2026-04-17 02:00:00
备份类型: full
备份文件: /backup/jenkins/daily/jenkins-backup-full-20260417_020000.tar.gz
文件大小: 485M
耗时: 45 秒

Jenkins 数据大小: 2048 MB
磁盘可用空间: 150G

状态: SUCCESS
```

---

## 恢复流程

### 场景 1: 完全恢复(灾难恢复)

```bash
# 1. 列出可用备份
./restore.sh --list

# 2. 使用最新备份恢复
./restore.sh --latest

# 3. 或者指定备份文件恢复
./restore.sh /backup/jenkins/daily/jenkins-backup-full-20260417_020000.tar.gz

# 4. 查看恢复日志
tail -f /backup/jenkins/restore.log

# 5. 验证恢复
docker logs -f jenkins
```

### 场景 2: 模拟恢复(测试)

```bash
# 模拟恢复,不实际执行
./restore.sh /backup/jenkins/daily/jenkins-backup-full-20260417_020000.tar.gz --dry-run
```

### 场景 3: 强制恢复(跳过确认)

```bash
# 强制恢复,不询问确认
./restore.sh --latest --force
```

### 恢复后验证清单

- [ ] Jenkins Web 界面可访问
- [ ] 所有作业配置存在
- [ ] 凭证和密钥正常
- [ ] 插件已加载
- [ ] 用户可以登录
- [ ] 流水线可以执行

---

## 备份验证

### 自动化验证脚本

创建 `verify-backup.sh`:

```bash
#!/bin/bash

# 验证最新的备份文件
LATEST_BACKUP=$(find /backup/jenkins/daily -name "*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)

echo "验证备份: $LATEST_BACKUP"

# 1. 检查文件完整性
if tar -tzf "$LATEST_BACKUP" > /dev/null 2>&1; then
    echo "✅ 备份文件完整"
else
    echo "❌ 备份文件损坏"
    exit 1
fi

# 2. 检查关键文件
KEY_FILES=("config.xml" "secret.key")
for file in "${KEY_FILES[@]}"; do
    if tar -tzf "$LATEST_BACKUP" | grep -q "$file"; then
        echo "✅ 找到关键文件: $file"
    else
        echo "❌ 缺少关键文件: $file"
        exit 1
    fi
done

# 3. 检查备份大小
SIZE=$(du -sh "$LATEST_BACKUP" | cut -f1)
echo "✅ 备份大小: $SIZE"

# 4. 检查备份年龄
AGE_HOURS=$(( ($(date +%s) - $(stat -c %Y "$LATEST_BACKUP")) / 3600 ))
if [ $AGE_HOURS -lt 48 ]; then
    echo "✅ 备份新鲜度: ${AGE_HOURS}小时前"
else
    echo "⚠️  警告: 备份已超过 48 小时"
fi

echo ""
echo "备份验证通过! ✅"
```

### 定期验证计划

```bash
# 每周验证一次备份完整性
0 6 * * 1 /path/to/verify-backup.sh >> /backup/jenkins/logs/verify.log 2>&1
```

---

## 最佳实践

### 1. 异地备份

#### 方案 A: 云存储同步

```bash
# 安装 AWS CLI
pip install awscli

# 同步到 S3
aws s3 sync /backup/jenkins/monthly s3://your-bucket/jenkins-backups/

# 或使用阿里云 OSS
ossutil sync /backup/jenkins/monthly oss://your-bucket/jenkins-backups/
```

#### 方案 B: NFS/网络存储

```bash
# 挂载远程存储
mount -t nfs nas-server:/backup /mnt/nas-backup

# 复制到远程存储
cp /backup/jenkins/monthly/*.tar.gz /mnt/nas-backup/
```

### 2. 加密备份

```bash
# 使用 GPG 加密备份
gpg --symmetric --cipher-algo AES256 backup.tar.gz

# 解密
gpg --decrypt backup.tar.gz.gpg > backup.tar.gz
```

### 3. 备份监控

创建监控脚本 `monitor-backup.sh`:

```bash
#!/bin/bash

# 检查最新备份是否存在且不超过 24 小时
LATEST=$(find /backup/jenkins/daily -name "*.tar.gz" -mmin -1440 | head -1)

if [ -z "$LATEST" ]; then
    echo "❌ 警告: 过去 24 小时内没有备份!"
    # 发送告警
    curl -X POST "https://hooks.slack.com/services/YOUR/WEBHOOK" \
         -d '{"text":"Jenkins 备份失败告警!"}'
    exit 1
else
    echo "✅ 备份正常: $LATEST"
fi
```

### 4. 磁盘空间管理

```bash
# 监控备份目录使用情况
df -h /backup/jenkins

# 设置告警阈值
USAGE=$(df /backup/jenkins | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $USAGE -gt 80 ]; then
    echo "⚠️  备份磁盘使用率超过 80%: ${USAGE}%"
fi
```

### 5. 文档化

维护备份清单:

```markdown
## 备份清单

- [x] 每日自动备份运行正常
- [x] 每周备份验证通过
- [x] 每月恢复测试完成
- [x] 异地备份同步正常
- [x] 磁盘空间充足
- [x] 备份加密启用
```

---

## 监控和告警

### Prometheus 监控(可选)

如果使用 Prometheus,可以暴露备份指标:

```python
#!/usr/bin/env python3
# backup-metrics.py - 导出备份指标到 Prometheus

import os
import time
from prometheus_client import start_http_server, Gauge

BACKUP_DIR = "/backup/jenkins/daily"

# 定义指标
backup_age = Gauge('jenkins_backup_age_seconds', 'Age of latest backup')
backup_size = Gauge('jenkins_backup_size_bytes', 'Size of latest backup')

def collect_metrics():
    # 获取最新备份
    backups = sorted(
        [f for f in os.listdir(BACKUP_DIR) if f.endswith('.tar.gz')],
        key=lambda x: os.path.getmtime(os.path.join(BACKUP_DIR, x))
    )
    
    if backups:
        latest = os.path.join(BACKUP_DIR, backups[-1])
        age = time.time() - os.path.getmtime(latest)
        size = os.path.getsize(latest)
        
        backup_age.set(age)
        backup_size.set(size)

if __name__ == '__main__':
    start_http_server(8000)
    while True:
        collect_metrics()
        time.sleep(60)
```

### 邮件通知

修改 `backup.sh` 中的 `send_notification` 函数:

```bash
send_notification() {
    local subject=$1
    local body=$2
    
    if [ -n "$NOTIFY_EMAIL" ]; then
        mail -s "$subject" "$NOTIFY_EMAIL" <<EOF
Jenkins 备份通知

$body

时间: $(date)
主机: $(hostname)
EOF
    fi
}
```

### 钉钉/企业微信通知

```bash
send_dingtalk_notification() {
    local message=$1
    local webhook="YOUR_DINGTALK_WEBHOOK_URL"
    
    curl -X POST "$webhook" \
         -H "Content-Type: application/json" \
         -d "{
            \"msgtype\": \"text\",
            \"text\": {
                \"content\": \"Jenkins 备份通知\\n\\n${message}\"
            }
         }"
}
```

---

## 故障排查

### 问题 1: 备份失败 - 磁盘空间不足

**症状**: `No space left on device`

**解决**:
```bash
# 1. 检查磁盘使用
df -h /backup

# 2. 清理旧备份
./cleanup-old-backups.sh

# 3. 扩容磁盘或清理其他文件
```

### 问题 2: 备份文件损坏

**症状**: `tar: Unexpected EOF`

**解决**:
```bash
# 1. 删除损坏的备份
rm /backup/jenkins/daily/corrupted-backup.tar.gz

# 2. 重新执行备份
./backup.sh full

# 3. 检查磁盘健康状态
smartctl -a /dev/sda
```

### 问题 3: 恢复后 Jenkins 无法启动

**症状**: Jenkins 容器不断重启

**解决**:
```bash
# 1. 查看日志
docker logs jenkins

# 2. 检查权限
ls -la /data/jenkins_home

# 3. 修复权限
chown -R 1000:1000 /data/jenkins_home

# 4. 如果仍然失败,恢复到之前的备份
./restore.sh /backup/jenkins/daily/previous-backup.tar.gz --force
```

### 问题 4: Cron 任务未执行

**症状**: 没有自动生成备份

**解决**:
```bash
# 1. 检查 cron 服务状态
systemctl status cron

# 2. 查看 cron 日志
grep CRON /var/log/syslog | tail -20

# 3. 手动测试脚本
./backup.sh full

# 4. 检查 cron 语法
crontab -l
```

---

## 附录

### A. 完整的备份目录结构

```
/backup/jenkins/
├── daily/                    # 每日备份
│   ├── jenkins-backup-full-20260417_020000.tar.gz
│   ├── jenkins-backup-full-20260416_020000.tar.gz
│   └── ...
├── weekly/                   # 每周备份
│   ├── jenkins-backup-full-20260414_020000.tar.gz
│   └── ...
├── monthly/                  # 每月备份
│   ├── jenkins-backup-full-20260401_020000.tar.gz
│   └── ...
├── logs/                     # 日志文件
│   ├── backup.log
│   ├── restore.log
│   └── verify.log
├── latest-backup-report.txt  # 最新备份报告
└── latest-restore-report.txt # 最新恢复报告
```

### B. 快速参考命令

```bash
# 备份相关
./backup.sh full                      # 执行备份
./backup.sh --help                    # 查看帮助

# 恢复相关
./restore.sh --list                   # 列出备份
./restore.sh --latest                 # 恢复最新
./restore.sh file.tar.gz --dry-run   # 模拟恢复

# 监控相关
tail -f /backup/jenkins/backup.log   # 查看备份日志
cat /backup/jenkins/latest-backup-report.txt  # 查看报告

# 维护相关
crontab -l                           # 查看定时任务
df -h /backup                        # 检查磁盘空间
```

### C. 备份策略检查表

每月执行一次:

- [ ] 验证最新备份完整性
- [ ] 测试恢复流程(在测试环境)
- [ ] 检查磁盘空间使用率
- [ ] 审查备份日志是否有错误
- [ ] 更新备份文档
- [ ] 验证异地备份同步
- [ ] 检查告警通知是否正常

---

**最后更新**: 2026-04-17  
**版本**: 1.0
