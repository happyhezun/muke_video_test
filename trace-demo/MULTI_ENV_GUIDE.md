# Trace Demo 多环境配置指南

## 1. 概述

本项目支持三个运行环境：**开发环境(dev)**、**测试环境(test)**、**生产环境(prod)**。通过 Maven Profile 和 Spring Boot Profile 机制实现不同环境的配置隔离和灵活切换。

---

## 2. 环境说明

### 2.1 开发环境 (dev)
- **用途**: 本地开发和调试
- **特点**: 
  - 日志级别: DEBUG (详细信息)
  - SkyWalking: 本地 Docker 容器 (127.0.0.1:11800)
  - 超时时间: 较长(方便调试)
  - 错误信息: 完整堆栈跟踪
- **适用场景**: 开发人员本地调试

### 2.2 测试环境 (test)
- **用途**: 集成测试和功能验证
- **特点**:
  - 日志级别: INFO (标准信息)
  - SkyWalking: 测试服务器 (test-skywalking.example.com:11800)
  - 超时时间: 标准配置
  - 错误信息: 标准格式
- **适用场景**: QA 测试、UAT 验收

### 2.3 生产环境 (prod)
- **用途**: 线上正式运行
- **特点**:
  - 日志级别: WARN (仅警告和错误)
  - SkyWalking: 生产集群 (prod-skywalking.example.com:11800)
  - 超时时间: 较短(快速失败)
  - 错误信息: 精简(不暴露敏感信息)
  - 性能优化: 启用连接池、异步日志等
- **适用场景**: 生产部署

---

## 3. 配置文件结构

每个服务模块包含以下配置文件:

```
src/main/resources/
├── application.yml              # 主配置文件(通用配置 + profile激活)
├── application-dev.yml          # 开发环境配置
├── application-test.yml         # 测试环境配置
├── application-prod.yml         # 生产环境配置
└── logback-spring.xml           # 日志配置(支持profile)
```

### 3.1 配置加载顺序

Spring Boot 按以下优先级加载配置:
1. `application.yml` (基础配置)
2. `application-{profile}.yml` (环境特定配置,会覆盖基础配置)

---

## 4. Maven Profile 配置

### 4.1 编译打包

在项目根目录执行:

```bash
# 开发环境(默认,可省略-Pdev)
mvn clean package

# 或显式指定
mvn clean package -Pdev

# 测试环境
mvn clean package -Ptest

# 生产环境
mvn clean package -Pprod
```

Maven 会在编译时将 `@spring.profiles.active@` 占位符替换为对应的环境名称。

### 4.2 验证打包结果

编译完成后,检查 JAR 包中的配置文件:

```bash
# 查看订单服务JAR包中的配置文件
jar tf trace-order/target/trace-order-1.0.0.jar | grep application

# 解压查看具体内容
unzip -p trace-order/target/trace-order-1.0.0.jar BOOT-INF/classes/application.yml | grep "active:"
```

应看到: `active: dev` (或 test/prod,取决于使用的 Profile)

---

## 5. 启动服务

### 5.1 方式一: 直接运行 JAR 包

```bash
# 开发环境
java -jar trace-order/target/trace-order-1.0.0.jar --spring.profiles.active=dev

# 测试环境
java -jar trace-order/target/trace-order-1.0.0.jar --spring.profiles.active=test

# 生产环境
java -jar trace-order/target/trace-order-1.0.0.jar --spring.profiles.active=prod
```

### 5.2 方式二: 使用环境变量

```bash
# 设置环境变量
export SPRING_PROFILES_ACTIVE=prod

# 启动服务(自动读取环境变量)
java -jar trace-order/target/trace-order-1.0.0.jar
```

### 5.3 方式三: Maven 运行时指定

```bash
# 适用于开发阶段快速测试
cd trace-order
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

### 5.4 带 SkyWalking Agent 启动

```bash
# 开发环境
java -javaagent:./skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-order-dev \
     -Dskywalking.collector.backend_service=127.0.0.1:11800 \
     -jar trace-order/target/trace-order-1.0.0.jar \
     --spring.profiles.active=dev

# 测试环境
java -javaagent:./skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-order-test \
     -Dskywalking.collector.backend_service=test-skywalking.example.com:11800 \
     -jar trace-order/target/trace-order-1.0.0.jar \
     --spring.profiles.active=test

# 生产环境
java -javaagent:./skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-order-prod \
     -Dskywalking.collector.backend_service=prod-skywalking.example.com:11800 \
     -jar trace-order/target/trace-order-1.0.0.jar \
     --spring.profiles.active=prod
```

---

## 6. 完整启动示例

### 6.1 开发环境完整启动流程

```bash
# 1. 编译打包(开发环境)
mvn clean package -Pdev

# 2. 启动 SkyWalking (可选)
docker-compose up -d

# 3. 终端1: 启动库存服务
java -javaagent:./skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-inventory-dev \
     -Dskywalking.collector.backend_service=127.0.0.1:11800 \
     -jar trace-inventory/target/trace-inventory-1.0.0.jar \
     --spring.profiles.active=dev

# 4. 终端2: 启动订单服务
java -javaagent:./skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-order-dev \
     -Dskywalking.collector.backend_service=127.0.0.1:11800 \
     -jar trace-order/target/trace-order-1.0.0.jar \
     --spring.profiles.active=dev

# 5. 终端3: 启动网关服务
java -javaagent:./skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-gateway-dev \
     -Dskywalking.collector.backend_service=127.0.0.1:11800 \
     -jar trace-gateway/target/trace-gateway-1.0.0.jar \
     --spring.profiles.active=dev
```

### 6.2 生产环境完整启动流程

```bash
# 1. 编译打包(生产环境)
mvn clean package -Pprod

# 2. 终端1: 启动库存服务
nohup java -javaagent:./skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-inventory-prod \
     -Dskywalking.collector.backend_service=prod-skywalking.example.com:11800 \
     -Xms512m -Xmx1024m \
     -jar trace-inventory/target/trace-inventory-1.0.0.jar \
     --spring.profiles.active=prod > /var/log/trace-inventory.out 2>&1 &

# 3. 终端2: 启动订单服务
nohup java -javaagent:./skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-order-prod \
     -Dskywalking.collector.backend_service=prod-skywalking.example.com:11800 \
     -Xms512m -Xmx1024m \
     -jar trace-order/target/trace-order-1.0.0.jar \
     --spring.profiles.active=prod > /var/log/trace-order.out 2>&1 &

# 4. 终端3: 启动网关服务
nohup java -javaagent:./skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-gateway-prod \
     -Dskywalking.collector.backend_service=prod-skywalking.example.com:11800 \
     -Xms512m -Xmx1024m \
     -jar trace-gateway/target/trace-gateway-1.0.0.jar \
     --spring.profiles.active=prod > /var/log/trace-gateway.out 2>&1 &
```

---

## 7. 验证环境配置

### 7.1 查看启动日志

服务启动时,会在日志中输出激活的 Profile:

```
The following profiles are active: dev
```

### 7.2 健康检查接口

```bash
# 检查订单服务
curl http://localhost:8081/order/health

# 检查库存服务
curl http://localhost:8082/inventory/health

# 检查网关服务
curl http://localhost:8080/actuator/health
```

### 7.3 查看 SkyWalking UI

访问对应环境的 SkyWalking UI:
- 开发环境: http://localhost:8088
- 测试环境: http://test-skywalking.example.com:8088
- 生产环境: http://prod-skywalking.example.com:8088

在服务列表中应看到:
- `trace-order-dev` / `trace-order-test` / `trace-order-prod`
- `trace-inventory-dev` / `trace-inventory-test` / `trace-inventory-prod`
- `trace-gateway-dev` / `trace-gateway-test` / `trace-gateway-prod`

---

## 8. 各环境配置差异详解

### 8.1 日志级别

| 环境 | Root 级别 | 应用级别 | 说明 |
|------|----------|---------|------|
| dev  | INFO     | DEBUG   | 详细调试信息 |
| test | INFO     | INFO    | 标准运行信息 |
| prod | WARN     | INFO    | 仅警告和关键信息 |

### 8.2 SkyWalking 配置

| 环境 | Collector 地址 | 服务命名 |
|------|---------------|---------|
| dev  | 127.0.0.1:11800 | xxx-dev |
| test | test-skywalking.example.com:11800 | xxx-test |
| prod | prod-skywalking.example.com:11800 | xxx-prod |

### 8.3 超时配置

| 环境 | 超时时间 | 说明 |
|------|---------|------|
| dev  | 5000ms  | 较长,方便调试 |
| test | 3000ms  | 标准配置 |
| prod | 2000ms  | 较短,快速失败 |

### 8.4 网关路由

| 环境 | Order 服务地址 | Inventory 服务地址 |
|------|---------------|-------------------|
| dev  | localhost:8081 | localhost:8082 |
| test | trace-order:8081 | trace-inventory:8082 |
| prod | trace-order:8081 | trace-inventory:8082 |

---

## 9. 最佳实践

### 9.1 开发阶段

- 使用 `-Pdev` 或不指定 Profile(默认 dev)
- 启用 SkyWalking 本地容器进行链路追踪
- 日志级别设为 DEBUG,便于排查问题

### 9.2 测试阶段

- 使用 `-Ptest` 编译打包
- 部署到测试服务器,连接到测试环境 SkyWalking
- 日志级别设为 INFO,平衡性能和可观测性

### 9.3 生产部署

- 使用 `-Pprod` 编译打包
- 通过 CI/CD 流水线自动化部署
- 使用环境变量或配置中心管理敏感信息(SkyWalking 地址等)
- 日志级别设为 WARN,减少磁盘 I/O
- 启用 JVM 参数优化: `-Xms512m -Xmx1024m`
- 使用 `nohup` 或 systemd 管理服务进程

### 9.4 配置管理建议

- **不要**在代码中硬编码敏感信息(密码、密钥等)
- 生产环境的 SkyWalking 地址等配置应通过以下方式管理:
  - 环境变量: `export SKYWALKING_COLLECTOR=prod-skywalking.example.com:11800`
  - 配置中心: Spring Cloud Config / Nacos / Apollo
  - Kubernetes ConfigMap / Secret

---

## 10. 常见问题

### Q1: 如何确认当前激活的是哪个环境?

**A**: 查看启动日志中的这行:
```
The following profiles are active: xxx
```

或在应用中添加端点返回当前环境:
```java
@GetMapping("/env")
public String getCurrentEnv(@Value("${spring.profiles.active}") String profile) {
    return "Current environment: " + profile;
}
```

### Q2: 为什么修改了配置文件但不生效?

**A**: 可能原因:
1. 未重新编译打包,旧的 JAR 包仍在使用
2. 启动时通过命令行参数覆盖了配置: `--spring.profiles.active=xxx`
3. 存在环境变量 `SPRING_PROFILES_ACTIVE`,优先级高于配置文件

### Q3: 如何在不同环境使用不同的数据库配置?

**A**: 在各环境的 yml 文件中分别配置:

```yaml
# application-dev.yml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/dev_db
    username: dev_user
    password: dev_password

# application-prod.yml
spring:
  datasource:
    url: jdbc:mysql://prod-db.example.com:3306/prod_db
    username: ${DB_USERNAME}  # 从环境变量读取
    password: ${DB_PASSWORD}
```

### Q4: Maven Profile 和 Spring Profile 有什么区别?

**A**:
- **Maven Profile**: 编译时使用,决定哪些配置文件被打包进 JAR
- **Spring Profile**: 运行时使用,决定激活哪套配置

本项目中,Maven Profile 会将 `@spring.profiles.active@` 替换为对应的值写入 `application.yml`,这样编译后的 JAR 包就有了默认的 Spring Profile。但仍可通过启动参数覆盖。

---

## 11. 总结

通过本项目的多环境配置方案,你可以:

✅ 一套代码,适配多个环境  
✅ 编译时通过 Maven Profile 选择环境  
✅ 运行时通过启动参数或环境变量切换环境  
✅ 不同环境使用不同的日志级别、SkyWalking 地址、超时配置等  
✅ 便于 CI/CD 自动化部署  

**核心命令回顾**:
```bash
# 编译
mvn clean package -Pdev|-Ptest|-Pprod

# 运行
java -jar xxx.jar --spring.profiles.active=dev|test|prod
```
