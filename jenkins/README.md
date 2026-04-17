# Jenkins CI/CD 自动化部署项目

## 项目简介

本项目使用 Docker Compose 快速部署 Jenkins 持续集成/持续部署(CI/CD)服务器,用于自动化构建、测试和部署应用。

## 功能特性

- 🚀 **Jenkins LTS**: 基于 JDK 21 的长期支持版本
- 🐳 **Docker 集成**: 容器内可直接执行 Docker 命令,支持容器化应用构建
- 💾 **数据持久化**: Jenkins 数据挂载到宿主机,确保数据安全
- 🌏 **时区配置**: 已配置为 Asia/Shanghai(中国时区)
- 🔄 **自动重启**: 异常退出时自动恢复服务
- 🔍 **代码扫描**: 集成 SonarQube 进行静态代码分析
- 🛡️ **容器扫描**: 集成 Trivy 进行镜像漏洞扫描
- ✅ **自动化测试**: 支持单元测试、集成测试并行执行
- 💿 **自动备份**: 完整的备份和恢复策略,支持定时自动备份

## 技术栈

- Jenkins (LTS with JDK 21)
- Docker & Docker Compose
- SonarQube (代码质量扫描)
- Trivy (容器安全扫描)
- Linux (root 权限运行)

## 快速开始

### 前置要求

- Docker
- Docker Compose

### 启动服务

```bash
docker-compose up -d
```

### 停止服务

```bash
docker-compose down
```

### 查看日志

```bash
docker-compose logs -f jenkins
```

## 访问方式

启动成功后,通过浏览器访问:

- **Web 管理界面**: http://localhost:6080
- **Agent 通信端口**: 50000

## 目录结构

```
.
├── docker-compose.yml        # Docker Compose 配置文件
├── Jenkinsfile               # Jenkins Pipeline 流水线配置
├── backup.sh                 # 自动备份脚本
├── restore.sh                # 数据恢复脚本
├── verify-backup.sh          # 备份验证脚本
├── cleanup-backups.sh        # 备份清理脚本
├── BACKUP_STRATEGY.md        # 备份策略详细文档
├── QUICKSTART.md             # 快速启动指南
├── FILES.md                  # 项目文件说明
├── Dockerfile.example        # Docker 构建示例
└── README.md                 # 项目说明文档
```

## 配置说明

### 端口映射

| 容器端口 | 宿主机端口 | 用途 |
|---------|-----------|------|
| 8080    | 6080      | Jenkins Web 界面 |
| 50000   | 50000     | Jenkins Agent 通信 |

### 数据卷挂载

| 宿主机路径 | 容器路径 | 用途 |
|-----------|---------|------|
| /data/jenkins_home | /var/jenkins_home | Jenkins 数据持久化 |
| /var/run/docker.sock | /var/run/docker.sock | Docker 守护进程 socket |
| /usr/bin/docker | /usr/bin/docker | Docker 命令(可选) |

### 环境变量

- `TZ=Asia/Shanghai`: 设置系统时区为中国标准时间
- `JAVA_OPTS=-Duser.timezone=Asia/Shanghai`: 设置 Java 时区
- `JENKINS_UC=https://mirrors.tuna.tsinghua.edu.cn/jenkins`: 插件更新中心镜像(国内加速)
- `JENKINS_UC_DOWNLOAD=https://mirrors.tuna.tsinghua.edu.cn/jenkins`: 插件下载镜像(国内加速)

## 🇨🇳 国内插件下载问题解决方案

### 快速修复 (推荐)

如果遇到插件下载失败或超时问题,运行一键修复脚本:

```bash
# 赋予执行权限
chmod +x fix-jenkins-plugins.sh

# 运行修复脚本
./fix-jenkins-plugins.sh
```

脚本会自动:
- ✅ 配置清华大学/华为云/阿里云镜像源
- ✅ 备份当前配置
- ✅ 修改更新中心和下载地址
- ✅ 重启 Jenkins 使配置生效

### 手动配置

**方法 1: Web 界面配置**

1. 登录 Jenkins: http://localhost:6080
2. 进入: **系统管理** → **插件管理** → **高级**
3. 找到 **升级站点**,将 URL 修改为:
   ```
   https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json
   ```
4. 点击 **提交** 并重启 Jenkins

**方法 2: 命令行配置**

```bash
docker exec -it jenkins bash -c "
cd /var/jenkins_home
sed -i 's|https://updates.jenkins.io/update-center.json|https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json|g' hudson.model.UpdateCenter.xml
sed -i 's|https://updates.jenkins.io/download/|https://mirrors.tuna.tsinghua.edu.cn/jenkins/|g' hudson.model.UpdateCenter.xml
"
docker restart jenkins
```

### 常用国内镜像源

| 镜像源 | 地址 | 推荐度 |
|--------|------|--------|
| 清华大学 | https://mirrors.tuna.tsinghua.edu.cn/jenkins | ⭐⭐⭐⭐⭐ |
| 华为云 | https://mirrors.huaweicloud.com/jenkins | ⭐⭐⭐⭐⭐ |
| 阿里云 | https://mirrors.aliyun.com/jenkins | ⭐⭐⭐⭐ |

### Maven/npm 依赖加速

**Maven 项目**: 在 `Jenkinsfile` 中配置阿里云镜像:

```groovy
sh '''
    mkdir -p ~/.m2
    cat > ~/.m2/settings.xml <<EOF
    <settings>
        <mirrors>
            <mirror>
                <id>aliyun</id>
                <mirrorOf>central</mirrorOf>
                <url>https://maven.aliyun.com/repository/public</url>
            </mirror>
        </mirrors>
    </settings>
    EOF
    mvn clean package
'''
```

**Node.js 项目**:

```bash
npm config set registry https://registry.npmmirror.com
```

### 详细文档

完整的插件下载问题解决方案请查看 [FIX_PLUGIN_DOWNLOAD.md](FIX_PLUGIN_DOWNLOAD.md),包含:
- 🔧 5 种解决方案
- 🐛 故障排查指南
- 💡 最佳实践
- 📋 完整配置示例

## 首次使用

1. 启动服务后,访问 http://localhost:6080
2. 获取初始管理员密码:
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```
3. 按照向导完成初始化配置
4. 安装推荐的插件或自定义选择插件
5. 创建管理员账户

## 集成代码扫描、容器扫描和自动化测试

### 架构概览

本项目的 Jenkins Pipeline 实现了完整的 DevSecOps 流程:

```
代码检出 → 代码扫描(SonarQube) → 依赖扫描 → 构建 → 自动化测试 → 
容器构建 → 容器扫描(Trivy) → 推送镜像 → 部署
```

### 1. 代码扫描 - SonarQube

#### 功能
- 静态代码分析
- 代码质量检查(复杂度、重复率、代码规范等)
- 安全漏洞检测
- 代码覆盖率统计
- 质量门禁(Quality Gate)控制

#### 前置准备

**步骤 1: 部署 SonarQube**

在 `docker-compose.yml` 中添加 SonarQube 服务:

```yaml
services:
  sonarqube:
    image: sonarqube:lts-community
    container_name: sonarqube
    ports:
      - "9000:9000"
    environment:
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    restart: unless-stopped

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
```

**步骤 2: 配置 Jenkins SonarQube 插件**

1. 进入 Jenkins → 系统管理 → 插件管理
2. 安装 "SonarQube Scanner" 插件
3. 进入 系统管理 → 系统配置 → SonarQube servers
4. 添加 SonarQube 服务器:
   - 名称: `SonarQube`
   - 服务器 URL: `http://sonarqube:9000`
   - 服务器认证令牌: 创建新的 Secret text 凭证

**步骤 3: 生成 SonarQube Token**

1. 登录 SonarQube (默认 admin/admin)
2. 点击右上角头像 → My Account → Security
3. 生成新令牌,复制保存
4. 在 Jenkins 中添加该令牌为凭证 (ID: `sonarqube-token`)

**步骤 4: 配置项目**

对于 Maven 项目,在 `pom.xml` 中添加:

```xml
<properties>
    <sonar.host.url>http://sonarqube:9000</sonar.host.url>
    <sonar.login>your-token-here</sonar.login>
</properties>
```

#### 使用方法

Pipeline 中已配置 SonarQube 扫描阶段:

```groovy
stage('代码扫描 - SonarQube') {
    steps {
        withSonarQubeEnv('SonarQube') {
            sh 'mvn sonar:sonar'
        }
        timeout(time: 5, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
}
```

质量门禁不通过时,流水线将自动中止。

---

### 2. 依赖安全扫描

#### 功能
- 检测第三方依赖的已知漏洞
- 基于 CVE 数据库进行匹配
- 生成漏洞报告

#### Maven 项目

使用 OWASP Dependency Check:

```groovy
sh '''
    mvn dependency-check:check \
        -DdependencyCheck.failOnCVSS=7.0
'''
```

#### Node.js 项目

使用 npm audit:

```groovy
sh 'npm audit --audit-level=high'
```

---

### 3. 自动化测试

#### 功能
- 单元测试并行执行
- 集成测试
- 代码覆盖率收集
- 测试结果报告生成

#### 配置说明

Pipeline 使用 `parallel` 指令并行执行单元测试和集成测试:

```groovy
stage('自动化测试') {
    parallel {
        stage('单元测试') {
            steps {
                // 执行单元测试
                // 发布 JUnit 测试报告
                // 发布覆盖率报告
            }
        }
        
        stage('集成测试') {
            steps {
                // 执行集成测试
            }
        }
    }
}
```

#### 测试结果展示

- **JUnit 报告**: 自动解析 XML 格式的测试结果
- **HTML 覆盖率报告**: 通过 publishHTML 插件展示
- **趋势图**: Jenkins 自动记录历史测试结果

#### 支持的测试框架

- **Java**: JUnit, TestNG (Maven/Gradle)
- **JavaScript/TypeScript**: Jest, Mocha, Jasmine
- **Python**: pytest, unittest
- **Go**: go test

---

### 4. 容器安全扫描 - Trivy

#### 功能
- 扫描容器镜像中的操作系统漏洞
- 检测应用依赖的安全问题
- 支持多种输出格式(table, json, sarif)
- 基于 CVSS 评分过滤高危漏洞

#### 前置准备

Trivy 会在 Pipeline 执行时自动安装,也可以预先安装到 Jenkins 容器中。

#### 使用方法

Pipeline 中已配置 Trivy 扫描:

```groovy
stage('容器安全扫描 - Trivy') {
    steps {
        sh """
            # 扫描 HIGH 和 CRITICAL 级别的漏洞
            trivy image \
                --exit-code 1 \
                --severity HIGH,CRITICAL \
                ${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
        """
    }
}
```

#### 参数说明

- `--exit-code 1`: 发现漏洞时返回错误码,中断流水线
- `--severity HIGH,CRITICAL`: 只扫描高危和严重漏洞
- `--format table/json`: 输出格式
- `--output`: 报告文件路径

#### 自定义漏洞阈值

可以调整扫描策略:

```bash
# 只阻断 CRITICAL 级别
trivy image --severity CRITICAL --exit-code 1 <image>

# 忽略特定 CVE
trivy image --ignorefile .trivyignore <image>
```

创建 `.trivyignore` 文件忽略已知误报:

```
# 示例:忽略特定 CVE
CVE-2021-XXXXX
```

---

### 完整流水线示例

查看 [Jenkinsfile](Jenkinsfile) 获取完整的流水线配置。

主要阶段包括:

1. **代码检出** - 从 Git 仓库拉取代码
2. **代码扫描** - SonarQube 静态分析
3. **依赖扫描** - OWASP Dependency Check
4. **应用构建** - Maven/npm/Gradle 构建
5. **自动化测试** - 单元测试 + 集成测试(并行)
6. **容器构建** - Docker build
7. **容器扫描** - Trivy 镜像漏洞扫描
8. **镜像推送** - 推送到镜像仓库
9. **应用部署** - 部署到生产环境(main 分支)

---

### 必需的 Jenkins 插件

在 Jenkins 中安装以下插件以支持完整功能:

#### 核心插件
- Pipeline
- Git
- Docker Pipeline

#### 代码质量
- SonarQube Scanner
- Warnings Next Generation

#### 测试报告
- JUnit
- HTML Publisher
- Code Coverage API

#### 安全扫描
- OWASP Dependency-Check
- Trivy (通过 shell 脚本调用)

#### 通知
- Email Extension
-钉钉/企业微信插件(可选)

---

### 凭证配置

在 Jenkins → 系统管理 → 凭证 中配置以下凭证:

| 凭证 ID | 类型 | 用途 |
|--------|------|------|
| `sonarqube-token` | Secret text | SonarQube 访问令牌 |
| `docker-registry-credentials` | Username with password | Docker 镜像仓库登录信息 |
| `git-credentials` | Username with password | Git 仓库认证(如需) |

---

### 环境变量配置

根据实际项目修改 `Jenkinsfile` 中的环境变量:

```groovy
environment {
    SONARQUBE_URL = 'http://sonarqube:9000'
    DOCKER_REGISTRY = 'your-registry.com'  // 修改为你的镜像仓库
    IMAGE_NAME = 'your-app'                // 修改为你的应用名称
}
```

---

### 分支策略

当前配置仅对 `main` 分支执行部署:

```groovy
stage('部署应用') {
    when {
        branch 'main'
    }
    steps {
        // 部署逻辑
    }
}
```

可以根据需要扩展:

```groovy
when {
    anyOf {
        branch 'main'
        branch 'release/*'
    }
}
```

---

### 监控和告警

#### 流水线状态通知

Pipeline 的 `post` 部分配置了失败时的邮件通知:

```groovy
post {
    failure {
        mail to: 'team@example.com',
             subject: "流水线失败: ${env.JOB_NAME}",
             body: "请检查: ${env.BUILD_URL}"
    }
}
```

可以扩展为:
- 钉钉机器人通知
- 企业微信 webhook
- Slack 通知
- Prometheus 指标采集

---

### 性能优化建议

1. **并行执行**: 测试阶段已使用 parallel 并行执行
2. **缓存依赖**: 使用 Docker 层缓存加速构建
3. **增量扫描**: SonarQube 支持增量分析
4. **资源限制**: 为 Jenkins 分配足够的 CPU 和内存

```
# docker-compose.yml 中添加资源限制
services:
  jenkins:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 4G
```

---

### 故障排查

#### SonarQube 连接失败

```bash
# 检查 SonarQube 是否运行
docker ps | grep sonarqube

# 查看 SonarQube 日志
docker logs sonarqube

# 测试网络连通性
docker exec jenkins curl http://sonarqube:9000
```

#### Trivy 安装失败

```bash
# 手动安装 Trivy
docker exec -it jenkins bash
apt-get update && apt-get install -y trivy
```

#### 测试报告未生成

检查测试框架是否正确输出 JUnit XML 格式:

```xml
<!-- Maven surefire 插件自动生成 -->
target/surefire-reports/*.xml
```

## 注意事项

⚠️ **安全提示**: 
- 当前配置以 root 用户运行并启用特权模式,生产环境建议根据实际需求调整权限
- 请及时修改默认密码并配置 HTTPS
- 建议配置防火墙规则限制访问

💡 **数据备份**:
- 定期备份 `/data/jenkins_home` 目录
- 可使用 Jenkins 内置的 ThinBackup 插件进行自动化备份

## 常见问题

### 1. 权限问题

如果遇到权限问题,确保:
```bash
sudo chown -R 1000:1000 /data/jenkins_home
```

### 2. 端口冲突

如果 6080 端口被占用,可修改 `docker-compose.yml` 中的端口映射:
```yaml
ports:
  - "其他端口:8080"
```

### 3. Docker 命令不可用

某些系统可能需要额外配置 Docker 命令挂载,请根据实际系统调整。

## 许可证

本项目仅供学习和个人使用。

## 联系方式

如有问题或建议,欢迎提 Issue。

## 备份和恢复

### 快速备份

```bash
# 赋予脚本执行权限
chmod +x backup.sh restore.sh verify-backup.sh cleanup-backups.sh

# 手动执行备份
./backup.sh full

# 查看备份报告
cat /backup/jenkins/latest-backup-report.txt
```

### 配置自动备份

```bash
# 编辑 crontab
crontab -e

# 添加每日凌晨 2 点自动备份
0 2 * * * /path/to/backup.sh full >> /backup/jenkins/logs/cron-backup.log 2>&1
```

### 数据恢复

```bash
# 列出可用备份
./restore.sh --list

# 使用最新备份恢复
./restore.sh --latest

# 或指定备份文件恢复
./restore.sh /backup/jenkins/daily/jenkins-backup-full-20260417_020000.tar.gz
```

### 备份验证

```bash
# 验证最新备份
./verify-backup.sh

# 验证所有备份
./verify-backup.sh --all
```

### 清理过期备份

```bash
# 模拟清理(不实际删除)
./cleanup-backups.sh --dry-run

# 执行清理
./cleanup-backups.sh

# 查看统计信息
./cleanup-backups.sh --stats
```

### 详细文档

完整的备份策略说明请查看 [BACKUP_STRATEGY.md](BACKUP_STRATEGY.md),包括:

- 📋 3-2-1 备份原则
- ⏰ 自动备份配置(Cron/Systemd)
- 🔄 恢复流程和验证
- 📊 监控和告警
- 💡 最佳实践
