# Trace Demo 微服务示例项目文档

## 1. 项目概述

本项目是一个基于 Spring Cloud Gateway 的微服务演示系统，集成了 Apache SkyWalking 分布式链路追踪功能。项目旨在演示微服务间的基本调用、网关路由配置、健康检查机制以及分布式追踪的实现。

### 1.1 核心功能
- **统一网关入口**: 通过 Spring Cloud Gateway 实现请求路由转发
- **服务间调用**: 订单服务调用库存服务的 RESTful API
- **分布式追踪**: 集成 SkyWalking 实现全链路监控
- **健康检查**: 各服务提供健康检查端点

---

## 2. 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Java | 1.8 | 编程语言 |
| Spring Boot | 2.4.4 | 应用框架 |
| Spring Cloud | 2020.0.5 | 微服务框架 |
| Spring Cloud Gateway | 3.x | API 网关 |
| Maven | - | 构建工具 |
| Apache SkyWalking | 9.0.0 | 分布式追踪 |
| Docker Compose | - | 容器编排 |

---

## 3. 项目架构

```
trace-demo/
├── skywalking-agent/           # SkyWalking Agent 目录
│   ├── activations/            # 激活插件
│   ├── bootstrap-plugins/      # 启动插件
│   ├── config/
│   │   └── agent.config        # Agent 配置文件
│   ├── optional-plugins/       # 可选插件
│   ├── optional-reporter-plugins/  # 可选报告插件
│   ├── plugins/                # 核心插件
│   └── skywalking-agent.jar    # Agent 主程序
├── trace-gateway/              # 网关服务 (端口: 8080)
├── trace-order/                # 订单服务 (端口: 8081)
├── trace-inventory/            # 库存服务 (端口: 8082)
├── docker-compose.yml          # SkyWalking 后端部署
├── pom.xml                     # 父项目 POM
└── README.md                   # 项目说明
```

### 3.1 服务架构图

```
┌─────────────────┐
│   客户端请求     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│  Gateway        │────▶│  Order Service  │
│  (端口: 8080)   │     │  (端口: 8081)   │
└─────────────────┘     └────────┬────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │ Inventory       │
                        │ (端口: 8082)    │
                        └─────────────────┘
```

---

## 4. 模块详解

### 4.1 Gateway 服务 (trace-gateway)

**端口**: 8080

**功能**: 作为统一入口，负责将请求路由到相应的后端服务。

**路由配置** (`GatewayApplication.java`):
```java
@Bean
public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
    return builder.routes()
            .route("order-service", r -> r.path("/order/**")
                    .uri("http://localhost:8081"))
            .route("inventory-service", r -> r.path("/inventory/**")
                    .uri("http://localhost:8082"))
            .build();
}
```

**路由规则**:
- `/order/**` → 转发到 `http://localhost:8081`
- `/inventory/**` → 转发到 `http://localhost:8082`

---

### 4.2 Order 服务 (trace-order)

**端口**: 8081

**功能**: 处理订单业务，并调用库存服务进行库存检查。

**API 端点**:

| 端点 | 方法 | 描述 |
|------|------|------|
| `/order/test` | GET | 测试接口 |
| `/order/health` | GET | 健康检查 |
| `/order/create` | POST | 创建订单（会调用库存服务） |

**核心代码** (`OrderController.java`):
```java
@PostMapping("/create")
public String createOrder() {
    // 调用库存服务
    String url = "http://localhost:8082/inventory/check?itemId=1";
    String inventoryResult = restTemplate.getForObject(url, String.class);
    return "Order Created Successfully. Inventory Status: " + inventoryResult;
}
```

---

### 4.3 Inventory 服务 (trace-inventory)

**端口**: 8082

**功能**: 模拟库存检查功能。

**API 端点**:

| 端点 | 方法 | 描述 |
|------|------|------|
| `/inventory/check` | GET | 检查库存状态 |
| `/inventory/health` | GET | 健康检查 |

**核心代码** (`InventoryController.java`):
```java
@GetMapping("/check")
public String checkInventory(@RequestParam(required = false, defaultValue = "1") String itemId) {
    return "Inventory OK for item: " + itemId;
}
```

---

## 5. SkyWalking 集成

### 5.1 架构组件

| 组件 | 端口 | 描述 |
|------|------|------|
| SkyWalking OAP | 11800 (gRPC), 12800 (HTTP) | 后端数据收集与处理服务 |
| SkyWalking UI | 8088 | 可视化界面 |

### 5.2 启动 SkyWalking 后端

```bash
docker-compose up -d
```

### 5.3 启动应用（带 SkyWalking Agent）

**Gateway 服务**:
```bash
cd trace-gateway
java -javaagent:../skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-gateway \
     -Dskywalking.collector.backend_service=127.0.0.1:11800 \
     -jar target/trace-gateway-1.0.0.jar
```

**Order 服务**:
```bash
cd trace-order
java -javaagent:../skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-order \
     -Dskywalking.collector.backend_service=127.0.0.1:11800 \
     -jar target/trace-order-1.0.0.jar
```

**Inventory 服务**:
```bash
cd trace-inventory
java -javaagent:../skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-inventory \
     -Dskywalking.collector.backend_service=127.0.0.1:11800 \
     -jar target/trace-inventory-1.0.0.jar
```

### 5.4 访问 SkyWalking UI

打开浏览器访问: http://localhost:8088

---

## 6. 快速开始

### 6.1 环境准备

- JDK 1.8+
- Maven 3.6+
- Docker & Docker Compose

### 6.2 构建项目

```bash
# 编译整个项目
mvn clean package

# 或者跳过测试
mvn clean package -DskipTests
```

### 6.3 启动服务

**步骤 1**: 启动 SkyWalking 后端
```bash
docker-compose up -d
```

**步骤 2**: 启动各个服务（使用 SkyWalking Agent）

```bash
# 启动库存服务
java -javaagent:./skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-inventory \
     -jar trace-inventory/target/trace-inventory-1.0.0.jar &

# 启动订单服务
java -javaagent:./skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-order \
     -jar trace-order/target/trace-order-1.0.0.jar &

# 启动网关服务
java -javaagent:./skywalking-agent/skywalking-agent.jar \
     -Dskywalking.agent.service_name=trace-gateway \
     -jar trace-gateway/target/trace-gateway-1.0.0.jar &
```

### 6.4 测试服务

**测试网关路由**:
```bash
# 测试订单服务
curl http://localhost:8080/order/health

# 测试库存服务
curl http://localhost:8080/inventory/health

# 创建订单（会触发库存检查）
curl -X POST http://localhost:8080/order/create
```

**直接访问服务**:
```bash
# 直接访问订单服务
curl http://localhost:8081/order/health

# 直接访问库存服务
curl http://localhost:8082/inventory/check?itemId=1
```

---

## 7. API 接口文档

### 7.1 Gateway 服务 (端口: 8080)

| 端点 | 方法 | 描述 |
|------|------|------|
| `/order/test` | GET | 测试订单服务 |
| `/order/health` | GET | 订单服务健康检查 |
| `/order/create` | POST | 创建订单 |
| `/inventory/check` | GET | 检查库存 |
| `/inventory/health` | GET | 库存服务健康检查 |

### 7.2 Order 服务 (端口: 8081)

| 端点 | 方法 | 描述 |
|------|------|------|
| `/order/test` | GET | 测试接口 |
| `/order/health` | GET | 健康检查 |
| `/order/create` | POST | 创建订单 |

### 7.3 Inventory 服务 (端口: 8082)

| 端点 | 方法 | 参数 | 描述 |
|------|------|------|------|
| `/inventory/check` | GET | itemId (可选，默认: 1) | 检查库存 |
| `/inventory/health` | GET | - | 健康检查 |

---

## 8. SkyWalking Agent 配置

### 8.1 核心配置项

配置文件位置: `skywalking-agent/config/agent.config`

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `agent.service_name` | `Your_ApplicationName` | 服务名称 |
| `agent.sample_n_per_3_secs` | `-1` | 每3秒采样数，-1表示关闭 |
| `collector.backend_service` | `127.0.0.1:11800` | OAP 后端地址 |
| `logging.level` | `INFO` | 日志级别 |
| `logging.output` | `FILE` | 日志输出方式 (FILE/CONSOLE) |

### 8.2 支持的插件

**核心插件** (plugins/):
- Spring MVC
- Spring WebFlux
- Spring Cloud Gateway
- HTTP Client (Apache HttpClient, OkHttp, RestTemplate)
- JDBC (MySQL, PostgreSQL, H2 等)
- Redis (Jedis, Lettuce, Redisson)
- MQ (Kafka, RabbitMQ, RocketMQ)
- RPC (Dubbo, gRPC)
- 数据库 (MongoDB, Elasticsearch, Cassandra 等)

**可选插件** (optional-plugins/):
- Spring Cloud Gateway 插件
- Spring 注解插件
- 自定义增强插件
- 追踪忽略插件graph LR
    Client[客户端] --> GW[Gateway:8080]
    GW -->|/order/**| Order[Order:8081]
    GW -->|/inventory/**| Inv[Inventory:8082]
    Order -->|RestTemplate| Inv

---

## 9. 常见问题

### 9.1 macOS DNS 解析警告

**问题**: 启动时出现 Netty DNS 解析警告

**解决方案**: 已在 `pom.xml` 中配置 Netty 版本和 macOS 原生 DNS 解析器依赖。

### 9.2 服务无法访问

**排查步骤**:
1. 检查服务是否已启动: `curl http://localhost:8081/order/health`
2. 检查网关路由配置是否正确
3. 查看服务日志确认端口绑定情况

### 9.3 SkyWalking 无数据

**排查步骤**:
1. 确认 OAP 服务已启动: `docker ps`
2. 检查 Agent 配置中的 `collector.backend_service` 地址
3. 查看 Agent 日志: `skywalking-agent/logs/skywalking-api.log`

---

## 10. 项目结构详解

```
trace-demo/
├── skywalking-agent/              # SkyWalking Java Agent
│   ├── activations/               # 激活插件 (10个)
│   ├── bootstrap-plugins/         # 启动插件 (4个)
│   ├── config/agent.config        # Agent 配置文件
│   ├── optional-plugins/          # 可选插件 (22个)
│   ├── optional-reporter-plugins/ # 可选报告插件 (4个)
│   ├── plugins/                   # 核心插件 (130+个)
│   ├── LICENSE
│   ├── NOTICE
│   └── skywalking-agent.jar       # Agent 主程序
│
├── trace-gateway/                 # 网关模块
│   └── src/main/java/com/example/gateway/
│       ├── GatewayApplication.java    # 启动类 + 路由配置
│       └── GatewayController.java     # 网关控制器
│
├── trace-order/                   # 订单服务模块
│   └── src/main/java/com/example/order/
│       ├── OrderApplication.java      # 启动类
│       └── controller/
│           └── OrderController.java   # 订单控制器
│
├── trace-inventory/               # 库存服务模块
│   └── src/main/java/com/example/inventory/
│       ├── InventoryApplication.java  # 启动类
│       └── controller/
│           └── InventoryController.java   # 库存控制器
│
├── docker-compose.yml             # SkyWalking OAP + UI 部署配置
├── pom.xml                        # 父 POM (依赖管理)
├── mvnw                           # Maven Wrapper
└── README.md                      # 项目说明
```

---

## 11. 贡献与许可

本项目仅供学习和演示使用。

SkyWalking 相关组件遵循 Apache License 2.0。

---

## 12. 参考链接

- [Spring Cloud Gateway 文档](https://spring.io/projects/spring-cloud-gateway)
- [Apache SkyWalking 官网](https://skywalking.apache.org/)
- [SkyWalking GitHub](https://github.com/apache/skywalking)
