# 环境标识功能说明

## 📌 功能概述

为了在运行时直观地区分当前服务所处的环境（开发/测试/生产），项目为每个服务添加了**环境标识变量**。该标识会在以下位置显示：

1. ✅ **服务启动日志** - 醒目的横幅显示
2. ✅ **健康检查接口** - 返回环境信息
3. ✅ **业务日志** - 每条日志前缀包含环境标识
4. ✅ **API响应** - 返回结果中包含环境信息

---

## 🎯 配置方式

### 配置文件中的环境标识

每个环境的配置文件中都定义了 `app.environment` 和 `app.environment-name` 两个变量：

```yaml
# application-dev.yml
app:
  environment: DEV
  environment-name: 开发环境

# application-test.yml
app:
  environment: TEST
  environment-name: 测试环境

# application-prod.yml
app:
  environment: PROD
  environment-name: 生产环境
```

---

## 📊 效果展示

### 1. 服务启动时的醒目提示

#### 订单服务启动日志示例

```log
=================================================
===  订单服务启动 - 当前环境: [DEV] 开发环境  ===
=================================================
==========================================================
Order Application is running!
Environment: [DEV] 开发环境
Configured Port: 8081
Actual Local Port: 8081
Local Access: 		http://localhost:8081/order/create
External Access: 	http://192.168.1.100:8081/order/create
==========================================================
Registered API Endpoints:
  -> [/order/test]
  -> [/order/health]
  -> [/order/create]
==========================================================
```

#### 库存服务启动日志示例

```log
=================================================
===  库存服务启动 - 当前环境: [TEST] 测试环境  ===
=================================================
==========================================================
Inventory Application is running!
Environment: [TEST] 测试环境
Configured Port: 8082
Actual Local Port: 8082
Local Access: 		http://localhost:8082/inventory/check
External Access: 	http://192.168.1.100:8082/inventory/check
==========================================================
```

#### 网关服务启动日志示例

```log
=================================================
===  网关服务启动 - 当前环境: [PROD] 生产环境  ===
=================================================
```

---

### 2. 健康检查接口返回

访问健康检查接口时，会清晰显示当前环境：

```bash
# 开发环境
$ curl http://localhost:8081/order/health
Order Service is UP | Environment: [DEV] 开发环境

# 测试环境
$ curl http://localhost:8082/inventory/health
Inventory Service is UP | Environment: [TEST] 测试环境

# 生产环境
$ curl http://localhost:8080/health
Gateway Service is UP | Environment: [PROD] 生产环境
```

---

### 3. 业务日志中的环境标识

所有业务日志都会带上环境前缀，方便在多环境混合日志中快速定位：

```log
[DEV] Order create endpoint hit
[DEV] Calling Inventory Service at URL: http://localhost:8082/inventory/check?itemId=1
[DEV] Received Inventory Result: Inventory OK for item: 1 | Environment: [DEV] 开发环境

[TEST] === Inventory check endpoint hit for itemId: 1 ===
[TEST] Returning response: Inventory OK for item: 1

[PROD] Order service health check - Environment: PROD
```

---

### 4. API 响应中的环境信息

业务接口的返回值也会包含环境标识：

```bash
# 创建订单
$ curl -X POST http://localhost:8080/order/create
Order Created Successfully. Inventory Status: Inventory OK for item: 1 | Environment: [DEV] 开发环境

# 检查库存
$ curl http://localhost:8080/inventory/check?itemId=100
Inventory OK for item: 100 | Environment: [DEV] 开发环境
```

---

## 🔍 实际应用场景

### 场景1: 多环境并行调试

当同时启动多个环境的服务时，可以清晰区分：

```bash
# 终端1 - 开发环境
java -jar trace-order.jar --spring.profiles.active=dev
# 输出: ===  订单服务启动 - 当前环境: [DEV] 开发环境  ===

# 终端2 - 测试环境
java -jar trace-order.jar --spring.profiles.active=test
# 输出: ===  订单服务启动 - 当前环境: [TEST] 测试环境  ===
```

### 场景2: 日志排查问题

在集中式日志系统（如 ELK）中搜索问题时，可以通过环境标识快速过滤：

```bash
# 只查看生产环境的错误日志
grep "\[PROD\]" /var/log/trace-order.log | grep "ERROR"

# 只查看开发环境的订单创建日志
grep "\[DEV\].*Order create" /var/log/trace-order.log
```

### 场景3: 防止误操作

在生产环境执行危险操作前，通过环境标识确认：

```bash
$ curl http://prod-server:8081/order/health
Order Service is UP | Environment: [PROD] 生产环境
# ⚠️ 看到 PROD 标识，确认是生产环境，谨慎操作
```

---

## 💡 技术实现

### 1. 配置注入

使用 Spring 的 `@Value` 注解从配置文件中读取环境变量：

```java
@Value("${app.environment:UNKNOWN}")
private String environment;

@Value("${app.environment-name:未知环境}")
private String environmentName;
```

### 2. 启动时打印

使用 `@PostConstruct` 注解在服务启动完成后打印环境标识：

```java
@PostConstruct
public void init() {
    log.info("=================================================");
    log.info("===  订单服务启动 - 当前环境: [{}] {}  ===", environment, environmentName);
    log.info("=================================================");
}
```

### 3. 日志前缀

在所有日志中使用格式化字符串添加环境标识：

```java
log.info("[{}] Order create endpoint hit", environment);
```

### 4. 接口返回

在健康检查和业务接口的返回值中拼接环境信息：

```java
return "Order Service is UP | Environment: [" + environment + "] " + environmentName;
```

---

## ✅ 验证步骤

### 1. 编译指定环境

```bash
# 编译开发环境
mvn clean package -Pdev
```

### 2. 启动服务

```bash
# 启动订单服务
java -jar trace-order/target/trace-order-1.0.0.jar --spring.profiles.active=dev
```

### 3. 观察启动日志

查看控制台输出，应该看到醒目的环境标识横幅。

### 4. 测试健康检查

```bash
curl http://localhost:8081/order/health
# 预期输出: Order Service is UP | Environment: [DEV] 开发环境
```

### 5. 测试业务接口

```bash
curl -X POST http://localhost:8080/order/create
# 预期输出中包含: Environment: [DEV] 开发环境
```

---

## 🎨 自定义环境标识

如果需要修改环境标识的显示内容，只需编辑对应的配置文件：

```yaml
# 例如：将开发环境改为英文显示
app:
  environment: DEV
  environment-name: Development Environment
```

或者添加更多环境：

```yaml
# 预发布环境
app:
  environment: STAGING
  environment-name: 预发布环境
```

记得在 `pom.xml` 中添加对应的 Maven Profile：

```xml
<profile>
    <id>staging</id>
    <properties>
        <spring.profiles.active>staging</spring.profiles.active>
    </properties>
</profile>
```

---

## 📝 总结

通过环境标识功能，您可以：

✅ **一眼识别** - 启动日志中醒目的环境横幅  
✅ **快速定位** - 日志和接口返回中都包含环境信息  
✅ **防止误操** - 明确知道当前操作的是哪个环境  
✅ **便于排查** - 在多环境混合日志中快速过滤  
✅ **灵活扩展** - 轻松添加新的环境和自定义标识  

**核心原则**: 让环境信息无处不在，避免混淆和误操作！🎯
