# Jenkins CI/CD 快速启动指南

## 🚀 5 分钟快速开始

### 第一步:启动服务

```bash
# 启动 Jenkins 和 SonarQube
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志(可选)
docker-compose logs -f
```

### 第二步:初始化 Jenkins

1. **获取初始密码**
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```

2. **访问 Jenkins**
   - 浏览器打开: http://localhost:6080
   - 输入上一步获取的密码

3. **安装插件**
   - 选择 "安装推荐的插件"
   - 等待安装完成

4. **创建管理员账户**
   - 用户名、密码、邮箱等信息

### 第三步:配置 SonarQube

1. **访问 SonarQube**
   - 浏览器打开: http://localhost:9000
   - 默认登录: admin / admin

2. **生成令牌**
   - 点击右上角头像 → My Account → Security
   - Generate Tokens → 输入名称 → Generate
   - **复制并保存令牌**(只显示一次)

3. **在 Jenkins 中配置 SonarQube**
   
   a. 添加凭证:
   - Jenkins → 系统管理 → 凭证 → 系统 → 全局凭证
   - 添加凭证 → Secret text
   - ID: `sonarqube-token`
   - Secret: 粘贴刚才复制的令牌
   
   b. 配置 SonarQube 服务器:
   - Jenkins → 系统管理 → 系统配置
   - 找到 "SonarQube servers"
   - 勾选 "Enable injection of SonarQube server configuration"
   - 添加 SonarQube:
     - Name: `SonarQube`
     - Server URL: `http://sonarqube:9000`
     - Server authentication token: 选择 `sonarqube-token`

### 第四步:配置 Docker 镜像仓库凭证

1. **添加 Docker Registry 凭证**
   - Jenkins → 系统管理 → 凭证 → 系统 → 全局凭证
   - 添加凭证 → Username with password
   - ID: `docker-registry-credentials`
   - Username: 你的镜像仓库用户名
   - Password: 你的镜像仓库密码

### 第五步:创建流水线任务

1. **新建任务**
   - Jenkins 首页 → 新建任务
   - 输入任务名称
   - 选择 "流水线(Pipeline)" → 确定

2. **配置流水线**
   - 滚动到 "Pipeline" 部分
   - Definition: 选择 "Pipeline script from SCM"
   - SCM: 选择 Git
   - Repository URL: 你的 Git 仓库地址
   - Branch: `*/main` (或你的分支)
   - Script Path: `Jenkinsfile`

3. **保存并构建**
   - 点击 "保存"
   - 点击 "立即构建"

### 第六步:查看结果

1. **构建历史**
   - 点击左侧 "构建历史"
   - 点击最新的构建编号

2. **查看控制台输出**
   - 点击 "控制台输出"
   - 实时查看流水线执行日志

3. **查看测试报告**
   - 构建完成后,查看 "测试报告"
   - 查看 "代码覆盖率报告"

4. **查看 SonarQube 分析结果**
   - 访问 http://localhost:9000
   - 查看项目代码质量报告

---

## 📋 前置检查清单

在开始之前,确保:

- [ ] Docker 已安装并运行
- [ ] Docker Compose 已安装
- [ ] 端口 6080、9000、50000 未被占用
- [ ] 至少有 4GB 可用内存
- [ ] 至少有 10GB 可用磁盘空间

---

## 🔧 常用命令

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看日志
docker-compose logs -f jenkins
docker-compose logs -f sonarqube

# 进入 Jenkins 容器
docker exec -it jenkins bash

# 备份 Jenkins 数据
tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /data/jenkins_home

# 清理未使用的 Docker 资源
docker system prune -a
```

---

## ⚙️ 自定义配置

### 修改端口

编辑 `docker-compose.yml`:

```yaml
ports:
  - "8080:8080"  # 将 6080 改为 8080
```

### 调整资源限制

```yaml
services:
  jenkins:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
```

### 修改时区

```yaml
environment:
  - TZ=Asia/Shanghai  # 改为你需要的时区
```

---

## 🐛 常见问题

### 1. Jenkins 启动很慢

**原因**: 首次启动需要初始化大量数据

**解决**: 耐心等待 3-5 分钟,查看日志确认状态

```bash
docker-compose logs -f jenkins
```

### 2. SonarQube 无法启动

**原因**: Elasticsearch 需要特定的系统配置

**解决**: 

```bash
# 增加虚拟内存限制
sudo sysctl -w vm.max_map_count=262144

# 永久生效,添加到 /etc/sysctl.conf
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

### 3. 权限错误

**问题**: `Permission denied` 错误

**解决**:

```bash
# 修改数据目录权限
sudo chown -R 1000:1000 /data/jenkins_home
```

### 4. 端口冲突

**问题**: 端口已被其他服务占用

**解决**: 修改 `docker-compose.yml` 中的端口映射

```yaml
ports:
  - "6081:8080"  # 使用其他端口
```

### 5. Pipeline 执行失败

**检查步骤**:

1. 查看控制台输出,定位失败的阶段
2. 检查凭证是否正确配置
3. 检查网络连接(SonarQube、Docker Registry)
4. 检查 Jenkinsfile 语法

---

## 📊 监控和维护

### 健康检查

```bash
# 检查 Jenkins 状态
curl http://localhost:6080/login

# 检查 SonarQube 状态
curl http://localhost:9000/api/system/status

# 检查 Docker 容器状态
docker-compose ps
```

### 定期备份

```bash
#!/bin/bash
# backup.sh - Jenkins 数据备份脚本

BACKUP_DIR="/backup/jenkins"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# 备份 Jenkins 数据
tar -czf $BACKUP_DIR/jenkins-$DATE.tar.gz /data/jenkins_home

# 保留最近 7 天的备份
find $BACKUP_DIR -name "jenkins-*.tar.gz" -mtime +7 -delete

echo "Backup completed: jenkins-$DATE.tar.gz"
```

### 清理旧构建

在 Jenkins 中配置:
- 任务配置 → 丢弃旧的构建
- 保持构建天数: 7
- 保持最大构建数: 10

---

## 🎯 下一步

1. **定制 Jenkinsfile**: 根据项目需求调整流水线
2. **配置通知**: 设置邮件、钉钉等通知渠道
3. **添加更多扫描**: SAST、DAST 等安全扫描
4. **多环境部署**: 配置 dev/test/prod 环境
5. **性能优化**: 调整资源分配,优化构建速度

---

## 📚 参考资源

- [Jenkins 官方文档](https://www.jenkins.io/doc/)
- [SonarQube 文档](https://docs.sonarqube.org/)
- [Trivy 文档](https://aquasecurity.github.io/trivy/)
- [Docker 最佳实践](https://docs.docker.com/develop/dev-best-practices/)

---

**祝你使用愉快! 🎉**
