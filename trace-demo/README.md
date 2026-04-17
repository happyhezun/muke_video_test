# Trace Demo 微服务链路追踪示例项目

## 1. 项目概述

本项目是一个基于 Spring Cloud Gateway 的微服务演示系统，集成了 Apache SkyWalking 分布式链路追踪功能。项目旨在演示微服务间的基本调用、网关路由配置、健康检查机制以及分布式追踪的实现。

### 核心功能
- **统一网关入口**: 通过 Spring Cloud Gateway 实现请求路由转发
- **服务间调用**: 订单服务 (`trace-order`) 调用库存服务 (`trace-inventory`) 的 RESTful API
- **分布式追踪**: 集成 SkyWalking Agent 实现全链路监控
- **健康检查**: 各服务提供 `/health` 端点用于状态检测

---

## 2. 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Java | 1.8 | 编程语言 |
| Spring Boot | 2.4.4 | 应用框架 |
| Spring Cloud | 2020.0.5 | 微服务框架 |
| Spring Cloud Gateway | 3.x | API 网关 |
| Maven | 3.6+ | 构建工具 |
| Apache SkyWalking | 9.0.0 | 分布式追踪 (可选) |
| Docker Compose | - | SkyWalking 后端部署 |

---

## 3. 项目架构

### 3.1 模块结构

*(此处原文档缺失具体模块结构描述，建议补充或保持原样)*

### 3.2 调用链路图
```
graph LR
    Client[客户端] --> Gateway[Gateway :8080]
    Gateway -->|/order/**| Order[Order Service :8081]
    Gateway -->|/inventory/**| Inventory[Inventory Service :8082]
    Order -->|RestTemplate| Inventory
流程说明:

客户端请求发送至 Gateway (8080)。
Gateway 根据路径将请求路由至 Order Service (8081) 或 Inventory Service (8082)。
Order Service 在处理创建订单请求时，会通过 RestTemplate 直接调用 Inventory Service (8082) 检查库存。
```

---

## 4. 快速开始

### 4.1 环境准备

- JDK 1.8+
- Maven 3.6+
- Docker & Docker Compose (如需使用 SkyWalking)

### 4.2 构建项目

在项目根目录执行：

```
mvn clean package -DskipTests
```

### 4.3 启动服务

#### 方式一：普通启动 (无链路追踪)

启动库存服务:

```
cd trace-inventory
mvn spring-boot:run
# 或 java -jar target/trace-inventory-1.0.0.jar
```

启动订单服务:

```
cd trace-order
mvn spring-boot:run
```

启动网关服务:

```
cd trace-gateway
mvn spring-boot:run
```

#### 方式二：带 SkyWalking Agent 启动 (推荐)

启动 SkyWalking 后端:

```
docker-compose up -d
```

等待 OAP 和 UI 启动完成，UI 访问地址: http://localhost:8088

启动各服务 (附加 Agent): 假设 skywalking-agent 目录位于项目根目录下。

```
# 终端 1: 库存服务
java -javaagent:./skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-inventory \
     -Dskywalking.collector.backend_service=127.0.0.1:11800 \
     -jar trace-inventory/target/trace-inventory-1.0.0.jar

# 终端 2: 订单服务
java -javaagent:./skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-order \
     -Dskywalking.collector.backend_service=127.0.0.1:11800 \
     -jar trace-order/target/trace-order-1.0.0.jar

# 终端 3: 网关服务
java -javaagent:./skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-gateway \
     -Dskywalking.collector.backend_service=127.0.0.1:11800 \
     -jar trace-gateway/target/trace-gateway-1.0.0.jar
```

---

## 5. API 接口测试

服务启动后，可通过以下方式测试：

### 5.1 健康检查

```
服务	直连地址	网关地址	预期响应
Order	http://localhost:8081/order/health	http://localhost:8080/order/health	Order Service is UP
Inventory	http://localhost:8082/inventory/health	http://localhost:8080/inventory/health	Inventory Service is UP

```

### 5.2 业务接口

1. 创建订单 (触发链路调用)

此接口会由 Order 服务调用 Inventory 服务。

```
curl -X POST http://localhost:8080/order/create
```

预期响应:

```
Order Created Successfully. Inventory Status: Inventory OK for item: 1
```

2. 直接检查库存

```
curl http://localhost:8080/inventory/check?itemId=100
```

预期响应:

```
Inventory OK for item: 100
```

---

## 6. SkyWalking 监控

访问 SkyWalking UI: http://localhost:8088

点击顶部菜单 Topology (拓扑图)，应能看到 trace-gateway -> trace-order -> trace-inventory 的调用关系。

点击 Trace (追踪)，可查看具体的请求链路详情、耗时及日志。

---

## 7. 常见问题排查

### 7.1 端口冲突

确保 8080, 8081, 8082, 11800, 12800, 8088 端口未被占用。

### 7.2 macOS DNS 解析警告

项目已在 pom.xml 中配置了 Netty 版本及 macOS 原生 DNS 解析器依赖 (netty-resolver-dns-native-macos)，以解决 Netty 在 macOS 上的 DNS 解析警告。

### 7.3 404 Not Found

检查 Gateway 路由配置 (GatewayApplication.java) 是否正确。

检查目标服务是否已启动并监听正确端口。

Order 服务启动时会打印注册的 API 端点，请查看控制台日志确认。

### 7.4 SkyWalking 无数据

确认 Docker 容器正常运行: `docker ps`

检查启动命令中的 -Dskywalking.collector.backend_service 地址是否正确 (默认 127.0.0.1:11800)。

查看 Agent 日志: skywalking-agent/logs/skywalking-api.log。

---

## 8. 参考链接

- [Spring Cloud Gateway 官方文档]
- [Apache SkyWalking 官方文档]
