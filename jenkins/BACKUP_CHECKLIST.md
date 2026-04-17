# Jenkins 备份策略实施检查清单

## 📋 实施步骤

按照以下步骤完成备份策略的部署和配置。

---

## 第一阶段: 基础准备 (预计 15 分钟)

### 1. 创建备份目录

```bash
# 创建备份根目录
sudo mkdir -p /backup/jenkins/{daily,weekly,monthly,logs}

# 设置权限
sudo chown -R $(whoami):$(whoami) /backup/jenkins

# 验证
ls -la /backup/jenkins/
```

- [ ] 备份目录创建成功
- [ ] 权限设置正确
- [ ] 磁盘空间充足 (建议至少 50GB)

### 2. 复制脚本文件

```bash
# 确保脚本在合适的位置
cd /path/to/jenkins/project

# 验证所有脚本存在
ls -lh backup.sh restore.sh verify-backup.sh cleanup-backups.sh
```

- [ ] backup.sh 存在
- [ ] restore.sh 存在
- [ ] verify-backup.sh 存在
- [ ] cleanup-backups.sh 存在

### 3. 设置执行权限

```bash
chmod +x backup.sh restore.sh verify-backup.sh cleanup-backups.sh
```

- [ ] 所有脚本具有执行权限

---

## 第二阶段: 首次备份测试 (预计 10 分钟)

### 4. 执行手动备份

```bash
# 执行全量备份
./backup.sh full

# 查看输出,确认成功
echo $?  # 应该返回 0
```

- [ ] 备份执行成功
- [ ] 无错误信息
- [ ] 生成备份文件

### 5. 验证备份文件

```bash
# 查看备份文件
ls -lh /backup/jenkins/daily/

# 查看备份报告
cat /backup/jenkins/latest-backup-report.txt

# 验证备份完整性
./verify-backup.sh
```

- [ ] 备份文件存在
- [ ] 文件大小合理 (>10MB)
- [ ] 验证通过

### 6. 测试恢复流程

```bash
# 模拟恢复(不实际执行)
./restore.sh --latest --dry-run

# 查看将恢复的文件
tar -tzf /backup/jenkins/daily/*.tar.gz | head -20
```

- [ ] 模拟恢复成功
- [ ] 文件列表正确

---

## 第三阶段: 自动化配置 (预计 20 分钟)

### 7. 配置 Cron 定时任务

```bash
# 编辑 crontab
crontab -e

# 添加以下内容(修改路径):
# 每天凌晨 2 点备份
0 2 * * * /path/to/backup.sh full >> /backup/jenkins/logs/cron-backup.log 2>&1

# 每周日凌晨 6 点验证备份
0 6 * * 0 /path/to/verify-backup.sh >> /backup/jenkins/logs/cron-verify.log 2>&1

# 每月 1 号凌晨 3 点清理过期备份
0 3 1 * * /path/to/cleanup-backups.sh --force >> /backup/jenkins/logs/cron-cleanup.log 2>&1
```

- [ ] Crontab 编辑成功
- [ ] 任务已添加
- [ ] 路径正确

### 8. 验证 Cron 任务

```bash
# 查看当前 cron 任务
crontab -l

# 检查 cron 服务状态
systemctl status cron    # Ubuntu/Debian
# 或
systemctl status crond   # CentOS/RHEL
```

- [ ] Cron 任务显示正确
- [ ] Cron 服务运行中

### 9. 测试 Cron 执行

```bash
# 方法 1: 等待第二天凌晨 2 点自动执行

# 方法 2: 手动触发测试(模拟 cron 环境)
env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  /path/to/backup.sh full >> /backup/jenkins/logs/cron-test.log 2>&1

# 查看日志
tail -50 /backup/jenkins/logs/cron-test.log
```

- [ ] Cron 环境测试成功
- [ ] 日志记录正常

---

## 第四阶段: 监控和告警 (预计 15 分钟)

### 10. 配置邮件通知(可选)

```bash
# 编辑 backup.sh
vim backup.sh

# 修改以下行:
NOTIFY_EMAIL="admin@example.com"  # 填入你的邮箱
```

- [ ] 邮箱地址配置
- [ ] 系统已安装 mail 命令

### 11. 配置钉钉/企业微信通知(可选)

```bash
# 在 backup.sh 中添加 webhook 调用
# 参考 BACKUP_STRATEGY.md 中的示例
```

- [ ] Webhook URL 配置
- [ ] 通知测试成功

### 12. 设置磁盘空间监控

```bash
# 创建监控脚本
cat > /usr/local/bin/check-backup-disk.sh <<'EOF'
#!/bin/bash
USAGE=$(df /backup/jenkins | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $USAGE -gt 80 ]; then
    echo "警告: 备份磁盘使用率 ${USAGE}%" | mail -s "磁盘空间告警" admin@example.com
fi
EOF

chmod +x /usr/local/bin/check-backup-disk.sh

# 添加到 crontab,每小时检查
echo "0 * * * * /usr/local/bin/check-backup-disk.sh" | crontab -
```

- [ ] 监控脚本创建
- [ ] 定时任务配置

---

## 第五阶段: 异地备份 (预计 30 分钟)

### 13. 选择异地备份方案

**方案 A: 云存储 (推荐)**

```bash
# AWS S3
pip install awscli
aws configure  # 配置 AK/SK

# 阿里云 OSS
pip install ossutil
ossutil config  # 配置 AccessKey
```

- [ ] 云存储账号准备
- [ ] CLI 工具安装
- [ ] 认证配置完成

**方案 B: NAS/网络存储**

```bash
# 挂载 NFS
sudo mount -t nfs nas-server:/backup /mnt/nas-backup

# 或挂载 CIFS
sudo mount -t cifs //nas-server/backup /mnt/nas-backup -o username=user,password=pass
```

- [ ] 网络存储可用
- [ ] 挂载成功
- [ ] 写入测试通过

### 14. 配置同步脚本

```bash
# 创建同步脚本
cat > /usr/local/bin/sync-backup-to-cloud.sh <<'EOF'
#!/bin/bash
# 同步 monthly 备份到云存储
aws s3 sync /backup/jenkins/monthly/ s3://your-bucket/jenkins-backups/monthly/
EOF

chmod +x /usr/local/bin/sync-backup-to-cloud.sh
```

- [ ] 同步脚本创建
- [ ] 手动测试成功

### 15. 配置自动同步

```bash
# 添加到 crontab,每天凌晨 5 点同步
echo "0 5 * * * /usr/local/bin/sync-backup-to-cloud.sh >> /backup/jenkins/logs/sync.log 2>&1" | crontab -
```

- [ ] 自动同步配置
- [ ] 定时任务添加

---

## 第六阶段: 文档和培训 (预计 20 分钟)

### 16. 更新团队文档

```bash
# 确保团队成员了解:
# 1. 备份策略文档位置
# 2. 紧急恢复流程
# 3. 联系人列表
```

- [ ] 文档已分享给团队
- [ ] 关键人员知晓流程

### 17. 创建紧急联系卡片

打印 `BACKUP_QUICK_REFERENCE.md` 并放置在显眼位置。

- [ ] 快速参考卡片已打印
- [ ] 放置在运维工作台

### 18. 团队培训

组织一次简短的培训会议,内容包括:

- [ ] 备份策略介绍
- [ ] 如何执行手动备份
- [ ] 如何进行数据恢复
- [ ] 故障排查方法
- [ ] 紧急联系方式

---

## 第七阶段: 验收测试 (预计 30 分钟)

### 19. 完整流程测试

```bash
# 1. 执行备份
./backup.sh full

# 2. 验证备份
./verify-backup.sh

# 3. 模拟灾难(在测试环境)
docker stop jenkins
mv /data/jenkins_home /data/jenkins_home.test

# 4. 执行恢复
./restore.sh --latest --force

# 5. 验证恢复
docker logs -f jenkins

# 6. 访问 Web 界面
# http://localhost:6080

# 7. 清理测试
# docker stop jenkins
# rm -rf /data/jenkins_home
# mv /data/jenkins_home.test /data/jenkins_home
# docker start jenkins
```

- [ ] 备份成功
- [ ] 验证通过
- [ ] 恢复成功
- [ ] Jenkins 正常运行
- [ ] 数据和配置完整

### 20. 性能评估

```bash
# 记录以下指标:
# 1. 备份耗时
# 2. 备份文件大小
# 3. 恢复耗时
# 4. 磁盘空间使用率

echo "备份耗时: ___ 秒"
echo "备份大小: ___ MB"
echo "恢复耗时: ___ 秒"
echo "磁盘使用: ___ %"
```

- [ ] 性能指标记录
- [ ] 满足预期要求

---

## 第八阶段: 持续优化 ( ongoing )

### 21. 建立定期检查机制

**每周检查:**

- [ ] 备份是否正常运行
- [ ] 磁盘空间是否充足
- [ ] 备份验证是否通过
- [ ] 日志是否有错误

**每月检查:**

- [ ] 执行一次恢复测试
- [ ] 审查备份策略是否需要调整
- [ ] 清理测试数据
- [ ] 更新文档

**每季度检查:**

- [ ] 异地备份是否同步
- [ ] 评估备份保留策略
- [ ] 性能优化
- [ ] 安全审计

### 22. 持续改进

根据实际运行情况,调整:

- [ ] 备份频率
- [ ] 保留时间
- [ ] 通知方式
- [ ] 存储位置
- [ ] 压缩算法

---

## ✅ 验收标准

所有项目打勾后,备份策略实施完成:

### 基础功能
- [ ] 手动备份正常工作
- [ ] 自动备份按时执行
- [ ] 备份验证通过
- [ ] 恢复流程测试成功

### 自动化
- [ ] Cron 任务配置正确
- [ ] 日志记录完整
- [ ] 过期备份自动清理
- [ ] 磁盘空间监控

### 可靠性
- [ ] 异地备份配置
- [ ] 备份加密(如需要)
- [ ] 告警通知正常
- [ ] 灾难恢复演练成功

### 文档化
- [ ] 操作文档完整
- [ ] 团队成员培训
- [ ] 紧急联系卡片
- [ ] 定期检查清单

---

## 📞 支持资源

### 文档
- [README.md](README.md) - 项目主文档
- [BACKUP_STRATEGY.md](BACKUP_STRATEGY.md) - 详细备份策略
- [BACKUP_QUICK_REFERENCE.md](BACKUP_QUICK_REFERENCE.md) - 快速参考
- [QUICKSTART.md](QUICKSTART.md) - 快速启动指南

### 脚本
- `backup.sh` - 备份脚本
- `restore.sh` - 恢复脚本
- `verify-backup.sh` - 验证脚本
- `cleanup-backups.sh` - 清理脚本

### 外部资源
- [Jenkins 官方文档](https://www.jenkins.io/doc/)
- [Docker 备份最佳实践](https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes)

---

## 🎯 下一步

实施完成后:

1. **监控运行**: 观察一周,确保稳定
2. **收集团队反馈**: 优化流程和文档
3. **定期演练**: 每季度进行一次灾难恢复演练
4. **持续改进**: 根据实际需求调整策略

---

**实施日期**: _______________  
**实施人员**: _______________  
**验收人员**: _______________  
**完成状态**: □ 进行中  □ 已完成  □ 需调整

---

**祝实施顺利! 🎉**
