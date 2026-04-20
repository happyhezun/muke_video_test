# Trace Demo 多环境配置 - 快速参考

## 🚀 一分钟上手

### 1️⃣ 编译打包

```bash
# 开发环境 (默认)
mvn clean package

# 测试环境
mvn clean package -Ptest

# 生产环境
mvn clean package -Pprod
```

### 2️⃣ 启动服务

```bash
# 方式一: 命令行参数 (推荐)
java -jar trace-order/target/trace-order-1.0.0.jar --spring.profiles.active=dev

# 方式二: 环境变量
export SPRING_PROFILES_ACTIVE=test
java -jar trace-order/target/trace-order-1.0.0.jar

# 方式三: Maven 运行 (仅开发)
cd trace-order && mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

---

## 🎯 环境标识功能

### 启动时查看环境

服务启动时会显示醒目的环境横幅：

```
=================================================
===  订单服务启动 - 当前环境: [DEV] 开发环境  ===
=================================================
```

### 健康检查接口

```bash
# 查看当前环境
curl http://localhost:8081/order/health
# 返回: Order Service is UP | Environment: [DEV] 开发环境

curl http://localhost:8082/inventory/health
# 返回: Inventory Service is UP | Environment: [TEST] 测试环境

curl http://localhost:8080/health
# 返回: Gateway Service is UP | Environment: [PROD] 生产环境
```

### 日志中的环境标识

所有日志都会带上环境前缀：

```log
[DEV] Order create endpoint hit
[TEST] === Inventory check endpoint hit for itemId: 1 ===
[PROD] Order service health check - Environment: PROD
```

**详细文档**: [ENVIRONMENT_IDENTIFIER.md](ENVIRONMENT_IDENTIFIER.md)

---

## 📋 环境对比

| 特性 | dev (开发) | test (测试) | prod (生产) |
|------|-----------|------------|------------|
| **环境标识** | `[DEV] 开发环境` | `[TEST] 测试环境` | `[PROD] 生产环境` |
| **日志级别** | DEBUG | INFO | WARN |
| **SkyWalking** | 本地 Docker | 测试服务器 | 生产集群 |
| **超时时间** | 5000ms | 3000ms | 2000ms |
| **服务地址** | localhost | 服务名 | 服务名 |
| **性能优化** | ❌ | 部分 | ✅ |
| **错误信息** | 详细堆栈 | 标准 | 精简 |

---

## 🔧 完整启动示例

### 开发环境

```bash
# 1. 编译
mvn clean package -Pdev

# 2. 启动 SkyWalking (可选)
docker-compose up -d

# 3. 启动三个服务 (三个终端)
# 终端1 - 库存服务
java -jar trace-inventory/target/trace-inventory-1.0.0.jar \
  --spring.profiles.active=dev

# 终端2 - 订单服务
java -jar trace-order/target/trace-order-1.0.0.jar \
  --spring.profiles.active=dev

# 终端3 - 网关服务
java -jar trace-gateway/target/trace-gateway-1.0.0.jar \
  --spring.profiles.active=dev
```

### 生产环境

```bash
# 1. 编译
mvn clean package -Pprod

# 2. 启动服务 (后台运行)
nohup java -Xms512m -Xmx1024m \
  -jar trace-inventory/target/trace-inventory-1.0.0.jar \
  --spring.profiles.active=prod > /var/log/inventory.log 2>&1 &

nohup java -Xms512m -Xmx1024m \
  -jar trace-order/target/trace-order-1.0.0.jar \
  --spring.profiles.active=prod > /var/log/order.log 2>&1 &

nohup java -Xms512m -Xmx1024m \
  -jar trace-gateway/target/trace-gateway-1.0.0.jar \
  --spring.profiles.active=prod > /var/log/gateway.log 2>&1 &
```

---

## ✅ 验证环境

### 查看激活的 Profile

```bash
# 方法1: 查看启动日志
# 寻找: "The following profiles are active: xxx"
# 或查看醒目横幅: "===  XXX服务启动 - 当前环境: [XXX] XXX环境  ==="

# 方法2: 健康检查
curl http://localhost:8081/order/health
# 返回中包含: Environment: [DEV] 开发环境
```

### 检查 SkyWalking

访问对应环境的 SkyWalking UI:
- Dev: http://localhost:8088
- Test: http://test-skywalking.example.com:8088
- Prod: http://prod-skywalking.example.com:8088

服务名称应包含环境后缀:
- `trace-order-dev` / `trace-order-test` / `trace-order-prod`

---

## 📁 配置文件位置

```
trace-order/
├── src/main/resources/
│   ├── application.yml          # 主配置 + profile激活
│   ├── application-dev.yml      # 开发环境 (environment: DEV)
│   ├── application-test.yml     # 测试环境 (environment: TEST)
│   └── application-prod.yml     # 生产环境 (environment: PROD)

trace-inventory/
├── src/main/resources/
│   ├── application.yml
│   ├── application-dev.yml
│   ├── application-test.yml
│   └── application-prod.yml

trace-gateway/
├── src/main/resources/
│   ├── application.yml
│   ├── application-dev.yml
│   ├── application-test.yml
│   └── application-prod.yml
```

---

## 🎯 核心原理

### Maven Profile (编译时)
```xml
<!-- pom.xml -->
<profiles>
    <profile>
        <id>dev</id>
        <properties>
            <spring.profiles.active>dev</spring.profiles.active>
        </properties>
    </profile>
</profiles>

<!-- application.yml -->
spring:
  profiles:
    active: @spring.profiles.active@  <!-- Maven会替换这个占位符 -->
```

### Spring Profile (运行时)
```yaml
# application-dev.yml
app:
  environment: DEV
  environment-name: 开发环境
  
spring:
  config:
    activate:
      on-profile: dev  # 当激活dev profile时加载此文件
```

### Java 代码注入
```java
@Value("${app.environment:UNKNOWN}")
private String environment;

@Value("${app.environment-name:未知环境}")
private String environmentName;

@PostConstruct
public void init() {
    log.info("===  当前环境: [{}] {}  ===", environment, environmentName);
}
```

---

## 💡 最佳实践

### ✅ 推荐做法

1. **开发阶段**: 使用 `-Pdev`,日志级别 DEBUG,便于调试
2. **测试阶段**: 使用 `-Ptest`,连接到测试环境中间件
3. **生产部署**: 使用 `-Pprod`,通过 CI/CD 自动化部署
4. **敏感信息**: 使用环境变量或配置中心,不要硬编码
5. **环境确认**: 操作前通过健康检查接口确认当前环境

### ❌ 避免做法

1. 不要在代码中硬编码环境特定的配置
2. 不要在生产环境使用 DEBUG 日志级别
3. 不要忘记在切换环境时重新编译打包
4. 不要将敏感信息(密码、密钥)提交到版本控制
5. 不要忽略启动时的环境标识提示

---

## 🔍 常见问题

**Q: 如何确认当前是哪个环境?**  
A: 
1. 查看启动日志中的醒目横幅: `===  XXX服务启动 - 当前环境: [XXX] XXX环境  ===`
2. 访问健康检查接口: `curl http://localhost:8081/order/health`
3. 查看日志前缀: `[DEV]`, `[TEST]`, `[PROD]`

**Q: 修改配置后不生效?**  
A: 需要重新编译打包: `mvn clean package -P<env>`

**Q: 能否运行时切换环境?**  
A: 可以,通过启动参数覆盖: `--spring.profiles.active=xxx`

**Q: 环境变量和配置文件哪个优先级高?**  
A: 命令行参数 > 环境变量 > 配置文件

**Q: 如何防止在生产环境误操作?**  
A: 
1. 养成习惯：操作前先调用健康检查接口确认环境
2. 观察日志中的环境标识前缀
3. 生产环境的标识特别醒目，引起注意

---

## 📚 更多资源

- 📖 详细多环境配置文档: [MULTI_ENV_GUIDE.md](MULTI_ENV_GUIDE.md)
- 🎯 环境标识功能详解: [ENVIRONMENT_IDENTIFIER.md](ENVIRONMENT_IDENTIFIER.md)
- 🧪 验证脚本: `./test-profiles.sh`
- 🐳 Docker 部署: `docker-compose.yml`

---

**祝使用愉快! 🎉**
