# 项目文件说明

## 📁 文件清单

### 核心配置文件

#### 1. `docker-compose.yml`
**用途**: Docker Compose 编排配置文件

**包含服务**:
- **jenkins**: Jenkins CI/CD 服务器 (JDK 21 LTS)
  - 端口: 6080 (Web), 50000 (Agent)
  - 数据卷: `/data/jenkins_home`
  - Docker 集成: 挂载 Docker socket
  
- **sonarqube**: SonarQube 代码质量平台
  - 端口: 9000 (Web)
  - 数据卷: sonarqube_data, extensions, logs
  - 网络: ci-cd-network

**使用方法**:
```bash
docker-compose up -d    # 启动
docker-compose down     # 停止
```

---

#### 2. `Jenkinsfile`
**用途**: Jenkins Pipeline 流水线定义文件

**流水线阶段**:
1. ✅ **代码检出** - Git checkout
2. 🔍 **代码扫描** - SonarQube 静态分析 + 质量门禁
3. 🛡️ **依赖扫描** - OWASP Dependency Check
4. 🔨 **应用构建** - Maven/npm/Gradle
5. 🧪 **自动化测试** - 单元测试 + 集成测试(并行)
6. 🐳 **容器构建** - Docker build
7. 🔎 **容器扫描** - Trivy 镜像漏洞扫描
8. 📤 **镜像推送** - Push to Registry
9. 🚀 **应用部署** - Deploy (main branch only)

**关键特性**:
- 并行测试执行
- 质量门禁控制
- 失败自动通知
- 多语言支持 (Java/Node.js/Go)

---

### 文档文件

#### 3. `README.md`
**用途**: 项目主文档

**内容**:
- 项目简介和功能特性
- 技术栈说明
- 快速开始指南
- 详细的集成说明:
  - SonarQube 代码扫描配置
  - Trivy 容器扫描配置
  - 自动化测试配置
- 插件清单
- 凭证配置
- 故障排查

**适合人群**: 所有用户,特别是需要了解完整功能的技术人员

---

#### 4. `QUICKSTART.md`
**用途**: 5 分钟快速启动指南

**内容**:
- 分步启动教程 (6 个步骤)
- 前置检查清单
- 常用命令速查
- 自定义配置示例
- 常见问题解决
- 监控和维护指南

**适合人群**: 首次使用的用户,需要快速上手

---

#### 5. `FILES.md` (本文件)
**用途**: 项目文件说明文档

**内容**:
- 所有文件的详细说明
- 文件之间的关系
- 使用场景和建议

---

### 示例文件

#### 6. `Dockerfile.example`
**用途**: 多阶段 Docker 构建示例

**特点**:
- 两阶段构建 (builder + runtime)
- 基于 Alpine 的精简镜像
- 非 root 用户运行
- 健康检查配置
- 适用于 Java Spring Boot 应用

**如何使用**:
```bash
# 复制为项目的 Dockerfile
cp Dockerfile.example Dockerfile

# 根据实际需求修改
vim Dockerfile
```

---

## 🔄 文件关系图

```
docker-compose.yml          # 基础设施编排
    ├── jenkins 容器
    │   └── 使用 Jenkinsfile  # 流水线定义
    │       ├── SonarQube API  # 代码扫描
    │       ├── Trivy CLI      # 容器扫描
    │       └── Docker CLI     # 镜像构建
    │
    └── sonarqube 容器        # 代码质量平台
        └── 提供分析服务

Dockerfile.example          # 应用容器化示例
    └── 被 Jenkinsfile 引用构建
```

---

## 📖 阅读建议

### 新手用户
1. 先读 [`QUICKSTART.md`](QUICKSTART.md) - 快速启动
2. 遇到问题查阅 [`README.md`](README.md) 的故障排查部分

### 进阶用户
1. 仔细阅读 [`README.md`](README.md) - 了解完整功能
2. 研究 [`Jenkinsfile`](Jenkinsfile) - 定制流水线
3. 参考 [`Dockerfile.example`](Dockerfile.example) - 优化镜像构建

### 运维人员
1. 查看 [`docker-compose.yml`](docker-compose.yml) - 了解架构
2. 阅读 [`README.md`](README.md) 的监控维护部分
3. 参考 [`QUICKSTART.md`](QUICKSTART.md) 的备份脚本

---

## 🎯 使用场景

### 场景 1: 新项目初始化
```bash
# 1. 启动基础设施
docker-compose up -d

# 2. 按照 QUICKSTART.md 配置 Jenkins

# 3. 复制 Jenkinsfile 到项目根目录
cp ../jenkins/Jenkinsfile ./Jenkinsfile

# 4. 根据实际情况修改 Jenkinsfile
vim Jenkinsfile

# 5. 在 Jenkins 中创建流水线任务
```

### 场景 2: 现有项目集成
```bash
# 1. 只需复制 Jenkinsfile 到项目
cp ../jenkins/Jenkinsfile ./

# 2. 根据项目类型修改构建和测试命令

# 3. 在现有 Jenkins 中配置相关插件和凭证

# 4. 触发构建测试
```

### 场景 3: 仅使用代码扫描
```bash
# 1. 启动 SonarQube
docker-compose up -d sonarqube

# 2. 在项目中使用 sonar-scanner
mvn sonar:sonar -Dsonar.host.url=http://localhost:9000

# 3. 访问 http://localhost:9000 查看结果
```

### 场景 4: 仅使用容器扫描
```bash
# 1. 在 Jenkins 容器中安装 Trivy
docker exec -it jenkins apt-get install -y trivy

# 2. 扫描镜像
docker exec jenkins trivy image your-image:tag

# 3. 查看报告
```

---

## ⚙️ 自定义建议

### 根据项目类型调整

#### Java 项目
- 保持 `Jenkinsfile` 中的 Maven 命令
- 使用提供的 `Dockerfile.example`
- 配置 SonarQube for Java

#### Node.js 项目
- 修改构建命令为 `npm run build`
- 修改测试命令为 `npm test`
- 使用 Node.js 基础镜像

#### Python 项目
- 添加 pytest 测试阶段
- 使用 pylint/flake8 代码检查
- 使用 python-slim 基础镜像

#### Go 项目
- 使用 go build 构建
- 使用 go test 测试
- 使用 golang-alpine 镜像

### 根据团队规模调整

#### 小团队 (1-5人)
- 使用当前配置即可
- 重点关注核心功能

#### 中团队 (5-20人)
- 添加更多并行阶段
- 配置详细的通知机制
- 实施分支策略

#### 大团队 (20+人)
- 考虑 Jenkins Master-Agent 架构
- 实施资源配额管理
- 添加审计日志

---

## 🔐 安全建议

1. **生产环境不要使用 root**
   ```yaml
   # docker-compose.yml
   user: "1000:1000"  # 改为非 root 用户
   privileged: false   # 禁用特权模式
   ```

2. **启用 HTTPS**
   - 配置 Nginx 反向代理
   - 使用 Let's Encrypt 证书

3. **定期更新**
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

4. **限制访问**
   - 配置防火墙规则
   - 使用 VPN 或内网访问

5. **备份数据**
   - 定期备份 `/data/jenkins_home`
   - 测试恢复流程

---

## 📊 性能调优

### Jenkins 优化
```yaml
# docker-compose.yml
environment:
  - JAVA_OPTS=-Xmx4g -Xms2g  # 调整 JVM 内存
```

### SonarQube 优化
```yaml
# docker-compose.yml
environment:
  - SONAR_JVM_OPTS=-Xmx2g -Xms512m
```

### 构建加速
- 使用 Docker 层缓存
- 并行执行测试
- 增量编译

---

## 🆘 获取帮助

### 文档
- [README.md](README.md) - 完整文档
- [QUICKSTART.md](QUICKSTART.md) - 快速开始

### 日志
```bash
# Jenkins 日志
docker-compose logs -f jenkins

# SonarQube 日志
docker-compose logs -f sonarqube
```

### 社区
- Jenkins 官方论坛
- SonarQube Community
- GitHub Issues

---

**最后更新**: 2026-04-17
