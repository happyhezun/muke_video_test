# Jenkins 国内插件下载问题完整解决方案

## 🇨🇳 问题背景

由于网络原因,Jenkins 在国内访问官方插件中心非常缓慢或完全无法访问,导致:
- ❌ 初始化时插件安装失败
- ❌ 插件管理页面加载缓慢
- ❌ 插件更新超时
- ❌ Pipeline 依赖下载失败

---

## ✅ 解决方案 (按推荐顺序)

### 方案 1: 使用国内镜像源 (⭐⭐⭐⭐⭐ 强烈推荐)

#### 步骤 1: 修改插件更新中心地址

**方法 A: 通过 Web 界面配置**

1. 登录 Jenkins: http://localhost:6080
2. 进入: **系统管理** → **插件管理** → **高级**
3. 找到 **升级站点** 部分
4. 将 URL 修改为国内镜像:

```
https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json
```

或者使用其他镜像:
```
https://mirrors.huaweicloud.com/jenkins/updates/update-center.json
https://mirrors.aliyun.com/jenkins/updates/update-center.json
```

5. 点击 **提交**
6. 重启 Jenkins

**方法 B: 直接修改配置文件**

```bash
# 进入 Jenkins 容器
docker exec -it jenkins bash

# 修改更新中心配置
cd /var/jenkins_home
sed -i 's|https://updates.jenkins.io/update-center.json|https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json|g' hudson.model.UpdateCenter.xml

# 重启 Jenkins
exit
docker restart jenkins
```

---

#### 步骤 2: 修改 downloads 镜像地址

编辑 `hudson.model.UpdateCenter.xml`:

```bash
docker exec -it jenkins bash
vi /var/jenkins_home/hudson.model.UpdateCenter.xml
```

将所有 `https://updates.jenkins.io/download/` 替换为:
```
https://mirrors.tuna.tsinghua.edu.cn/jenkins/
```

或使用华为云:
```
https://mirrors.huaweicloud.com/jenkins/
```

保存后重启 Jenkins。

---

#### 步骤 3: 一键脚本配置 (推荐)

创建配置脚本 `fix-jenkins-mirror.sh`:

```bash
#!/bin/bash

echo "配置 Jenkins 国内镜像源..."

# 清华镜像
MIRROR_URL="https://mirrors.tuna.tsinghua.edu.cn/jenkins"

# 进入容器执行配置
docker exec -it jenkins bash -c "
cd /var/jenkins_home

# 备份原配置
cp hudson.model.UpdateCenter.xml hudson.model.UpdateCenter.xml.bak

# 修改更新中心地址
sed -i 's|https://updates.jenkins.io/update-center.json|${MIRROR_URL}/updates/update-center.json|g' hudson.model.UpdateCenter.xml

# 修改下载地址
sed -i 's|https://updates.jenkins.io/download/|${MIRROR_URL}/|g' hudson.model.UpdateCenter.xml

echo '配置完成!'
cat hudson.model.UpdateCenter.xml
"

# 重启 Jenkins
echo "重启 Jenkins..."
docker restart jenkins

echo "完成! 请等待 1-2 分钟后访问 http://localhost:6080"
```

使用方法:
```bash
chmod +x fix-jenkins-mirror.sh
./fix-jenkins-mirror.sh
```

---

### 方案 2: Docker Compose 环境变量配置 (⭐⭐⭐⭐)

在启动前配置镜像地址,修改 `docker-compose.yml`:

```yaml
services:
  jenkins:
    image: jenkins/jenkins:lts-jdk21
    container_name: jenkins
    user: root
    privileged: true
    ports:
      - "6080:8080"
      - "50000:50000"
    volumes:
      - /data/jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - ./update-center.json:/usr/share/jenkins/ref/update-center.json:ro  # 挂载自定义配置
    environment:
      - TZ=Asia/Shanghai
      - JAVA_OPTS=-Duser.timezone=Asia/Shanghai
      - JENKINS_UC=https://mirrors.tuna.tsinghua.edu.cn/jenkins
      - JENKINS_UC_DOWNLOAD=https://mirrors.tuna.tsinghua.edu.cn/jenkins
      - JENKINS_UPDATE_CENTER=https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json
    restart: unless-stopped
    networks:
      - ci-cd-network
    depends_on:
      - sonarqube
```

然后重新创建容器:
```bash
docker-compose down
docker-compose up -d
```

---

### 方案 3: 离线安装插件 (⭐⭐⭐)

如果网络完全不可用,可以离线安装插件。

#### 步骤 1: 下载插件

在有网络的机器上下载所需插件:

```bash
# 访问清华镜像站
https://mirrors.tuna.tsinghua.edu.cn/jenkins/plugins/

# 或使用 wget 下载
wget https://mirrors.tuna.tsinghua.edu.cn/jenkins/plugins/sonar/2.15/sonar.hpi
wget https://mirrors.tuna.tsinghua.edu.cn/jenkins/plugins/git/4.11.0/git.hpi
```

#### 步骤 2: 上传到 Jenkins

**方法 A: Web 界面上传**

1. 登录 Jenkins
2. 进入: **系统管理** → **插件管理** → **高级**
3. 找到 **上传插件** 部分
4. 选择 `.hpi` 或 `.jpi` 文件
5. 点击 **上传**
6. 重启 Jenkins

**方法 B: 命令行复制**

```bash
# 复制插件文件到 Jenkins 插件目录
docker cp sonar.hpi jenkins:/var/jenkins_home/plugins/
docker cp git.hpi jenkins:/var/jenkins_home/plugins/

# 设置权限
docker exec -it jenkins chown -R jenkins:jenkins /var/jenkins_home/plugins/

# 重启 Jenkins
docker restart jenkins
```

---

### 方案 4: 使用代理服务器 (⭐⭐)

如果有可用的代理服务器,可以配置 Jenkins 使用代理。

#### 步骤 1: 配置代理

编辑 `docker-compose.yml`:

```yaml
services:
  jenkins:
    environment:
      - HTTP_PROXY=http://your-proxy-server:port
      - HTTPS_PROXY=http://your-proxy-server:port
      - NO_PROXY=localhost,127.0.0.1
      - JAVA_OPTS=-Dhttp.proxyHost=your-proxy-server -Dhttp.proxyPort=port -Dhttps.proxyHost=your-proxy-server -Dhttps.proxyPort=port
```

#### 步骤 2: 重启服务

```bash
docker-compose down
docker-compose up -d
```

---

### 方案 5: 修改 DNS (⭐⭐)

有时是 DNS 解析问题,可以尝试修改 DNS。

```bash
# 修改宿主机的 DNS
sudo vi /etc/resolv.conf

# 添加国内 DNS
nameserver 114.114.114.114
nameserver 223.5.5.5
nameserver 8.8.8.8

# 重启 Docker 服务
sudo systemctl restart docker

# 重启 Jenkins
docker restart jenkins
```

---

## 🔧 常用国内镜像源

| 镜像源 | 地址 | 速度 | 稳定性 |
|--------|------|------|--------|
| **清华大学** | https://mirrors.tuna.tsinghua.edu.cn/jenkins | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **华为云** | https://mirrors.huaweicloud.com/jenkins | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **阿里云** | https://mirrors.aliyun.com/jenkins | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **腾讯云** | https://mirrors.cloud.tencent.com/jenkins | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

**推荐使用清华大学或华为云镜像。**

---

## 📋 完整配置示例

### 推荐的 docker-compose.yml

```yaml
version: '3.8'
services:
  jenkins:
    image: jenkins/jenkins:lts-jdk21
    container_name: jenkins
    user: root
    privileged: true
    ports:
      - "6080:8080"
      - "50000:50000"
    volumes:
      - /data/jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - /usr/bin/docker:/usr/bin/docker
    environment:
      - TZ=Asia/Shanghai
      - JAVA_OPTS=-Duser.timezone=Asia/Shanghai -Dhudson.model.UpdateCenter.updateCenterUrl=https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json
      - JENKINS_UC=https://mirrors.tuna.tsinghua.edu.cn/jenkins
      - JENKINS_UC_DOWNLOAD=https://mirrors.tuna.tsinghua.edu.cn/jenkins
    restart: unless-stopped
    networks:
      - ci-cd-network
    depends_on:
      - sonarqube

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
    networks:
      - ci-cd-network

networks:
  ci-cd-network:
    driver: bridge

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
```

---

## 🐛 故障排查

### 问题 1: 配置后仍然无法下载

**检查步骤**:

```bash
# 1. 确认配置已生效
docker exec -it jenkins cat /var/jenkins_home/hudson.model.UpdateCenter.xml

# 2. 测试网络连接
docker exec -it jenkins curl -I https://mirrors.tuna.tsinghua.edu.cn/jenkins

# 3. 查看 Jenkins 日志
docker logs -f jenkins | grep -i "update\|plugin\|download"

# 4. 检查 DNS 解析
docker exec -it jenkins nslookup mirrors.tuna.tsinghua.edu.cn
```

**解决方案**:
- 清除浏览器缓存
- 硬刷新页面 (Ctrl+F5)
- 重启 Jenkins 容器
- 尝试其他镜像源

---

### 问题 2: 初始化时插件安装失败

**解决方案**:

```bash
# 1. 跳过插件安装,先完成初始化
# 在初始化页面选择 "跳过插件安装"

# 2. 配置镜像源 (参考方案 1)

# 3. 手动安装必需插件
# 系统管理 → 插件管理 → 可选插件
# 搜索并安装:
# - Git
# - Docker Pipeline
# - SonarQube Scanner
# - Pipeline

# 4. 或者使用 CLI 批量安装
docker exec -it jenkins jenkins-cli -s http://localhost:8080 install-plugin git docker-workflow sonar scanner-api pipeline
```

---

### 问题 3: 特定插件下载失败

**解决方案**:

```bash
# 1. 单独下载该插件
PLUGIN_NAME="sonar"
PLUGIN_VERSION="2.15"
wget https://mirrors.tuna.tsinghua.edu.cn/jenkins/plugins/${PLUGIN_NAME}/${PLUGIN_VERSION}/${PLUGIN_NAME}.hpi

# 2. 上传到 Jenkins
docker cp ${PLUGIN_NAME}.hpi jenkins:/var/jenkins_home/plugins/

# 3. 设置权限并重启
docker exec -it jenkins chown jenkins:jenkins /var/jenkins_home/plugins/${PLUGIN_NAME}.hpi
docker restart jenkins
```

---

### 问题 4: Maven/Gradle 依赖下载慢

**解决方案**:

在 `Jenkinsfile` 中配置国内 Maven 仓库:

```groovy
stage('构建应用') {
    steps {
        script {
            sh '''
                # 配置阿里云 Maven 镜像
                mkdir -p ~/.m2
                cat > ~/.m2/settings.xml <<EOF
                <settings>
                    <mirrors>
                        <mirror>
                            <id>aliyun</id>
                            <mirrorOf>central</mirrorOf>
                            <name>Aliyun Maven</name>
                            <url>https://maven.aliyun.com/repository/public</url>
                        </mirror>
                    </mirrors>
                </settings>
                EOF
                
                mvn clean package -DskipTests
            '''
        }
    }
}
```

对于 npm:
```bash
npm config set registry https://registry.npmmirror.com
```

对于 Gradle:
```groovy
repositories {
    maven { url 'https://maven.aliyun.com/repository/public' }
    mavenCentral()
}
```

---

## 🚀 快速修复脚本

创建 `fix-jenkins-plugins.sh`:

```bash
#!/bin/bash

set -e

echo "=========================================="
echo "  Jenkins 插件下载问题快速修复工具"
echo "=========================================="
echo ""

# 选择镜像源
echo "请选择镜像源:"
echo "1. 清华大学 (推荐)"
echo "2. 华为云"
echo "3. 阿里云"
read -p "请输入选项 (1-3): " choice

case $choice in
    1)
        MIRROR="https://mirrors.tuna.tsinghua.edu.cn/jenkins"
        echo "使用清华大学镜像..."
        ;;
    2)
        MIRROR="https://mirrors.huaweicloud.com/jenkins"
        echo "使用华为云镜像..."
        ;;
    3)
        MIRROR="https://mirrors.aliyun.com/jenkins"
        echo "使用阿里云镜像..."
        ;;
    *)
        echo "无效选项,使用清华大学镜像"
        MIRROR="https://mirrors.tuna.tsinghua.edu.cn/jenkins"
        ;;
esac

echo ""
echo "正在配置..."

# 备份配置
docker exec jenkins bash -c "cd /var/jenkins_home && cp -f hudson.model.UpdateCenter.xml hudson.model.UpdateCenter.xml.bak.$(date +%Y%m%d)" 2>/dev/null || true

# 修改配置
docker exec jenkins bash -c "
cd /var/jenkins_home
sed -i 's|https://updates.jenkins.io/update-center.json|${MIRROR}/updates/update-center.json|g' hudson.model.UpdateCenter.xml
sed -i 's|https://updates.jenkins.io/download/|${MIRROR}/|g' hudson.model.UpdateCenter.xml
"

echo "✅ 配置已更新"
echo ""
echo "正在重启 Jenkins..."
docker restart jenkins

echo ""
echo "=========================================="
echo "  配置完成!"
echo "=========================================="
echo ""
echo "镜像地址: ${MIRROR}"
echo ""
echo "下一步:"
echo "1. 等待 1-2 分钟让 Jenkins 完全启动"
echo "2. 访问: http://localhost:6080"
echo "3. 进入: 系统管理 → 插件管理 → 高级"
echo "4. 确认更新站点 URL 已更改"
echo ""
echo "如需恢复,执行:"
echo "docker exec jenkins bash -c 'cd /var/jenkins_home && mv hudson.model.UpdateCenter.xml.bak.* hudson.model.UpdateCenter.xml'"
echo ""
```

使用方法:
```bash
chmod +x fix-jenkins-plugins.sh
./fix-jenkins-plugins.sh
```

---

## 📊 验证配置是否生效

### 方法 1: Web 界面检查

1. 登录 Jenkins
2. 进入: **系统管理** → **插件管理** → **高级**
3. 查看 **升级站点** URL 是否为国内镜像地址

### 方法 2: 命令行检查

```bash
docker exec jenkins cat /var/jenkins_home/hudson.model.UpdateCenter.xml | grep -A 2 "<url>"
```

应该看到类似输出:
```xml
<url>https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json</url>
```

### 方法 3: 测试下载速度

```bash
# 测试镜像连接
docker exec jenkins curl -w "@curl-format.txt" -o /dev/null -s \
  https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json

# curl-format.txt 内容:
# time_namelookup:  %{time_namelookup}\n
# time_connect:     %{time_connect}\n
# time_starttransfer: %{time_starttransfer}\n
# time_total:       %{time_total}\n
```

---

## 💡 最佳实践

### 1. 首次初始化前配置

在首次启动 Jenkins **之前**就配置好镜像源:

```bash
# 1. 创建初始化脚本
mkdir -p /data/jenkins_home/init.groovy.d

cat > /data/jenkins_home/init.groovy.d/set-update-center.groovy <<'EOF'
import jenkins.model.*

def instance = Jenkins.getInstance()
def uc = instance.getUpdateCenter()

// 设置清华镜像
uc.getSites().each { site ->
    if (site.id == "default") {
        site.updateSiteUrl = "https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json"
    }
}

instance.save()
println "Update center configured to use Tsinghua mirror"
EOF

# 2. 启动 Jenkins
docker-compose up -d
```

### 2. 定期更新插件列表

```bash
# 每周更新一次插件列表
0 3 * * 0 docker exec jenkins jenkins-cli -s http://localhost:8080 reload-configuration
```

### 3. 监控插件下载状态

```bash
# 查看插件下载日志
docker logs jenkins | grep -i "plugin\|download" | tail -50
```

---

## 🎯 总结

### 推荐方案优先级

1. ⭐⭐⭐⭐⭐ **方案 1**: 使用国内镜像源 (最简单有效)
2. ⭐⭐⭐⭐ **方案 2**: Docker 环境变量配置 (适合新部署)
3. ⭐⭐⭐ **方案 3**: 离线安装 (网络完全不可用时)
4. ⭐⭐ **方案 4/5**: 代理/DNS (特定场景)

### 关键要点

- ✅ 优先使用清华大学或华为云镜像
- ✅ 首次启动前配置最佳
- ✅ 配置后务必重启 Jenkins
- ✅ 清除浏览器缓存
- ✅ 耐心等待 1-2 分钟让配置生效

### 常见问题速查

| 问题 | 解决方案 |
|------|---------|
| 插件下载超时 | 切换镜像源,使用清华或华为云 |
| 初始化失败 | 跳过插件安装,配置后再手动安装 |
| 配置不生效 | 重启 Jenkins,清除浏览器缓存 |
| 特定插件失败 | 单独下载离线安装 |
| Maven 依赖慢 | 配置阿里云 Maven 镜像 |

---

**祝你配置顺利! 🎉**

如仍有问题,请查看 Jenkins 日志:
```bash
docker logs -f jenkins
```
