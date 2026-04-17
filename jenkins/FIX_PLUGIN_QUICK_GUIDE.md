# Jenkins 插件下载问题 - 快速修复指南

## 🚨 问题症状

- ❌ 初始化时插件安装失败/超时
- ❌ 插件管理页面加载缓慢或空白
- ❌ 提示 "Connection timed out" 或 "Download failed"
- ❌ Maven/npm 依赖下载极慢

---

## ⚡ 一键修复 (30秒解决)

```bash
# 1. 运行修复脚本
chmod +x fix-jenkins-plugins.sh
./fix-jenkins-plugins.sh

# 2. 等待 1-2 分钟让 Jenkins 重启

# 3. 访问 http://localhost:6080 验证
```

**就这么简单!** 🎉

---

## 🔧 手动修复 (3步)

### 步骤 1: 修改更新中心

```bash
docker exec -it jenkins bash -c "
cd /var/jenkins_home
sed -i 's|https://updates.jenkins.io/update-center.json|https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json|g' hudson.model.UpdateCenter.xml
sed -i 's|https://updates.jenkins.io/download/|https://mirrors.tuna.tsinghua.edu.cn/jenkins/|g' hudson.model.UpdateCenter.xml
"
```

### 步骤 2: 重启 Jenkins

```bash
docker restart jenkins
```

### 步骤 3: 验证配置

```bash
# 查看配置是否生效
docker exec jenkins grep '<url>' /var/jenkins_home/hudson.model.UpdateCenter.xml

# 应该看到清华镜像地址
```

---

## 🌐 可用镜像源

| 镜像 | 地址 | 速度 |
|------|------|------|
| **清华大学** ⭐推荐 | https://mirrors.tuna.tsinghua.edu.cn/jenkins | ⭐⭐⭐⭐⭐ |
| **华为云** | https://mirrors.huaweicloud.com/jenkins | ⭐⭐⭐⭐⭐ |
| **阿里云** | https://mirrors.aliyun.com/jenkins | ⭐⭐⭐⭐ |

---

## 📦 Maven/npm 加速

### Maven

在 `Jenkinsfile` 中添加:

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
'''
```

### npm

```bash
npm config set registry https://registry.npmmirror.com
```

### Gradle

```groovy
repositories {
    maven { url 'https://maven.aliyun.com/repository/public' }
    mavenCentral()
}
```

---

## 🐛 故障排查

### 检查 1: 确认配置生效

```bash
docker exec jenkins cat /var/jenkins_home/hudson.model.UpdateCenter.xml | grep mirrors
```

### 检查 2: 测试网络连接

```bash
docker exec jenkins curl -I https://mirrors.tuna.tsinghua.edu.cn/jenkins
```

应该返回 `HTTP/2 200`

### 检查 3: 查看日志

```bash
docker logs -f jenkins | grep -i "plugin\|download\|error"
```

### 检查 4: 清除缓存

```bash
# 清除浏览器缓存,硬刷新 (Ctrl+F5)
# 或在 Jenkins Web 界面:
# 系统管理 → 插件管理 → 高级 → 立即获取
```

---

## 🔄 恢复原配置

如果需要使用官方源:

```bash
docker exec jenkins bash -c "
cd /var/jenkins_home
ls hudson.model.UpdateCenter.xml.bak.* | tail -1 | xargs -I {} mv {} hudson.model.UpdateCenter.xml
"
docker restart jenkins
```

---

## 💡 预防措施

### 新部署时配置

在 `docker-compose.yml` 中已预配置国内镜像:

```yaml
environment:
  - JENKINS_UC=https://mirrors.tuna.tsinghua.edu.cn/jenkins
  - JENKINS_UC_DOWNLOAD=https://mirrors.tuna.tsinghua.edu.cn/jenkins
  - JAVA_OPTS=-Dhudson.model.UpdateCenter.updateCenterUrl=https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json
```

### 首次启动前配置

创建初始化脚本 `/data/jenkins_home/init.groovy.d/set-mirror.groovy`:

```groovy
import jenkins.model.*
def uc = Jenkins.getInstance().getUpdateCenter()
uc.getSites().each { site ->
    if (site.id == "default") {
        site.updateSiteUrl = "https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json"
    }
}
Jenkins.getInstance().save()
```

---

## 📞 仍然有问题?

1. **查看详细文档**: [FIX_PLUGIN_DOWNLOAD.md](FIX_PLUGIN_DOWNLOAD.md)
2. **查看日志**: `docker logs -f jenkins`
3. **尝试其他镜像**: 切换到华为云或阿里云
4. **离线安装**: 手动下载 `.hpi` 文件上传

---

**祝你使用愉快! 🎉**
