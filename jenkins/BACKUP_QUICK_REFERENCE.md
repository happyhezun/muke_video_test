# Jenkins 备份快速参考

## 🚀 一键命令

```bash
# 立即备份
./backup.sh full

# 恢复最新备份
./restore.sh --latest

# 验证备份
./verify-backup.sh

# 清理过期备份
./cleanup-backups.sh
```

---

## 📅 自动备份配置

### 方法 1: Cron (推荐)

```bash
crontab -e

# 每天凌晨 2 点备份
0 2 * * * /path/to/backup.sh full >> /backup/jenkins/logs/cron.log 2>&1

# 每周验证备份
0 6 * * 1 /path/to/verify-backup.sh >> /backup/jenkins/logs/verify.log 2>&1

# 每月清理过期备份
0 3 1 * * /path/to/cleanup-backups.sh --force >> /backup/jenkins/logs/cleanup.log 2>&1
```

### 方法 2: Systemd Timer

```bash
# 创建服务
sudo tee /etc/systemd/system/jenkins-backup.service <<EOF
[Unit]
Description=Jenkins Backup
After=docker.service

[Service]
Type=oneshot
ExecStart=/path/to/backup.sh full

[Install]
WantedBy=multi-user.target
EOF

# 创建定时器
sudo tee /etc/systemd/system/jenkins-backup.timer <<EOF
[Unit]
Description=Daily Jenkins Backup

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 启用
sudo systemctl daemon-reload
sudo systemctl enable jenkins-backup.timer
sudo systemctl start jenkins-backup.timer
```

---

## 🔄 恢复流程

### 标准恢复

```bash
# 1. 查看可用备份
./restore.sh --list

# 2. 恢复最新备份
./restore.sh --latest

# 3. 查看日志
docker logs -f jenkins

# 4. 访问验证
# http://localhost:6080
```

### 强制恢复(跳过确认)

```bash
./restore.sh --latest --force
```

### 模拟恢复(测试)

```bash
./restore.sh /path/to/backup.tar.gz --dry-run
```

---

## 📊 监控命令

```bash
# 查看备份统计
./cleanup-backups.sh --stats

# 查看最新备份
ls -lh /backup/jenkins/daily/ | tail -5

# 查看磁盘使用
df -h /backup/jenkins

# 查看备份日志
tail -f /backup/jenkins/backup.log

# 查看备份报告
cat /backup/jenkins/latest-backup-report.txt
```

---

## ⚙️ 配置参数

### 修改保留策略

编辑 `backup.sh`:

```bash
# 保留天数
RETENTION_DAYS=30        # 默认 30 天

# 修改为 60 天
RETENTION_DAYS=60
```

编辑 `cleanup-backups.sh`:

```bash
DAILY_RETENTION_DAYS=30      # Daily 保留 30 天
WEEKLY_RETENTION_DAYS=84     # Weekly 保留 12 周
MONTHLY_RETENTION_DAYS=365   # Monthly 保留 12 个月
```

### 修改备份目录

编辑所有脚本中的:

```bash
BACKUP_BASE_DIR="/backup/jenkins"       # 备份存储目录
JENKINS_HOME="/data/jenkins_home"       # Jenkins 数据目录
```

### 配置通知邮箱

编辑 `backup.sh`:

```bash
NOTIFY_EMAIL="admin@example.com"  # 设置通知邮箱
```

---

## 🗂️ 目录结构

```
/backup/jenkins/
├── daily/              # 每日备份 (保留 30 天)
├── weekly/             # 每周备份 (保留 12 周)
├── monthly/            # 每月备份 (保留 12 个月)
├── logs/               # 日志文件
├── latest-backup-report.txt
└── latest-restore-report.txt
```

---

## 🐛 故障排查

### 备份失败

```bash
# 1. 查看日志
tail -100 /backup/jenkins/backup.log

# 2. 检查磁盘空间
df -h /backup/jenkins

# 3. 手动执行测试
./backup.sh full

# 4. 检查 Jenkins 是否运行
docker ps | grep jenkins
```

### 恢复失败

```bash
# 1. 查看恢复日志
tail -100 /backup/jenkins/restore.log

# 2. 检查备份文件完整性
tar -tzf /backup/jenkins/daily/xxx.tar.gz

# 3. 检查权限
ls -la /data/jenkins_home

# 4. 修复权限
chown -R 1000:1000 /data/jenkins_home

# 5. 查看 Jenkins 日志
docker logs jenkins
```

### Cron 未执行

```bash
# 1. 检查 cron 服务
systemctl status cron

# 2. 查看 cron 日志
grep CRON /var/log/syslog | tail -20

# 3. 检查 crontab
crontab -l

# 4. 手动测试
/path/to/backup.sh full
```

---

## 💡 最佳实践

### 1. 定期测试恢复

```bash
# 每月在测试环境执行一次恢复测试
./restore.sh --latest --force
```

### 2. 异地备份

```bash
# 同步到云存储
aws s3 sync /backup/jenkins/monthly s3://your-bucket/backups/

# 或复制到 NAS
rsync -av /backup/jenkins/monthly/ nas-server:/backup/jenkins/
```

### 3. 加密备份

```bash
# 加密
gpg --symmetric --cipher-algo AES256 backup.tar.gz

# 解密
gpg --decrypt backup.tar.gz.gpg > backup.tar.gz
```

### 4. 监控告警

```bash
# 添加到 crontab,每天检查
0 8 * * * /path/to/verify-backup.sh || echo "备份验证失败!" | mail -s "告警" admin@example.com
```

### 5. 文档化

维护备份清单,每月检查:

- [ ] 备份正常运行
- [ ] 恢复测试通过
- [ ] 磁盘空间充足
- [ ] 异地备份同步
- [ ] 告警通知正常

---

## 📞 紧急联系

### 关键命令速查

```bash
# 停止 Jenkins
docker stop jenkins

# 启动 Jenkins
docker start jenkins

# 重启 Jenkins
docker restart jenkins

# 查看实时日志
docker logs -f jenkins

# 进入容器
docker exec -it jenkins bash

# 紧急备份
./backup.sh full

# 紧急恢复
./restore.sh --latest --force
```

---

**提示**: 将此文件打印或保存为书签,以便紧急情况时快速查阅!
