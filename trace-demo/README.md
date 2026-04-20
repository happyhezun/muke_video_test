# Trace Demo 微服务链路追踪示例项目

## 📢 最新更新: 多环境配置支持

本项目现已支持**开发(dev)**、**测试(test)**、**生产(prod)**三个环境的配置管理!

### 快速开始多环境部署

```bash
# 1. 编译指定环境
mvn clean package -Pdev    # 开发环境(默认)
mvn clean package -Ptest   # 测试环境
mvn clean package -Pprod   # 生产环境

# 2. 启动服务
java -jar trace-order/target/trace-order-1.0.0.jar --spring.profiles.active=dev

# 详细文档请查看: MULTI_ENV_GUIDE.md
```

---

## 1. 项目概述

本项目是一个基于 Spring Cloud Gateway 的微服务演示系统，集成了 Apache SkyWalking 分布式链路追踪功能。项目旨在演示微服务间的基本调用、网关路由配置、健康检查机制以及分布式追踪的实现。

### 核心功能
- **统一网关入口**: 通过 Spring Cloud Gateway 实现请求路由转发
- **服务间调用**: 订单服务 (`trace-order`) 调用库存服务 (`trace-inventory`) 的 RESTful API
- **分布式追踪**: 集成 SkyWalking Agent 实现全链路监控
- **健康检查**: 各服务提供 `/health` 端点用于状态检测
- **✨ 多环境支持**: 一套代码适配 dev/test/prod 三个环境

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
- **Kubernetes & Helm 3.x+** (如需 K8s 部署)

### 4.2 构建项目

在项目根目录执行：

```
mvn clean package -DskipTests
```

### 4.3 启动服务

#### 🚀 方式零：Kubernetes Helm 部署 (推荐生产环境)

```bash
# 1. 构建Docker镜像
docker build -t your-registry/trace-order:1.0.0 trace-order/
docker build -t your-registry/trace-inventory:1.0.0 trace-inventory/
docker build -t your-registry/trace-gateway:1.0.0 trace-gateway/

# 推送到镜像仓库
docker push your-registry/trace-order:1.0.0
docker push your-registry/trace-inventory:1.0.0
docker push your-registry/trace-gateway:1.0.0

# 2. 使用Helm一键部署所有服务 (开发环境)
./deploy-all.sh -i -s all -e dev

# 3. 使用Helm部署生产环境
./deploy-all.sh -i -s all -e prod

# 4. 查看状态
./deploy-all.sh -st -s all

# 查看详细文档
cat HELM_CHARTS_GUIDE.md
```

**优势**:
- ✅ 声明式配置，版本可控
- ✅ 支持自动扩缩容 (HPA)
- ✅ 日志持久化存储 (PVC)
- ✅ 健康检查和自动重启
- ✅ 一键部署和回滚
- ✅ 完整的生产级特性

**包含的服务**:
- 🔹 **trace-order** - 订单服务 (端口 8081)
- 🔹 **trace-inventory** - 库存服务 (端口 8082)
- 🔹 **trace-gateway** - API网关 (端口 8080)

---

#### 方式一：本地启动 (无链路追踪)

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

## 7. 日志配置

### 7.1 日志文件位置

项目已配置 Logback 日志框架，所有服务的日志文件统一存储在**项目根目录**的 `logs/` 文件夹下：

```
trace-demo/
├── logs/
│   ├── trace-gateway.log              # 网关服务主日志
│   ├── trace-gateway-error.log        # 网关服务错误日志
│   ├── trace-gateway.2026-04-17.log   # 网关历史归档日志
│   ├── trace-order.log                # 订单服务主日志
│   ├── trace-order-error.log          # 订单服务错误日志
│   ├── trace-order.2026-04-17.log     # 订单历史归档日志
│   ├── trace-inventory.log            # 库存服务主日志
│   ├── trace-inventory-error.log      # 库存服务错误日志
│   └── trace-inventory.2026-04-17.log # 库存历史归档日志
```

### 7.2 日志配置特性

每个服务模块均包含 `logback-spring.xml` 配置文件，具备以下特性：

- **双输出模式**: 同时输出到控制台和文件，方便开发调试和生产排查
- **按天滚动**: 每天自动生成新的日志文件，格式为 `{service-name}.yyyy-MM-dd.log`
- **错误日志分离**: ERROR 级别日志单独记录到 `-error.log` 文件，便于快速定位问题
- **存储策略**: 
  - 保留最近 **30 天**的历史日志
  - 总文件大小限制为 **1GB**，超出后自动删除最旧的日志
- **异步写入**: 使用异步 Appender 提升性能，减少日志对业务线程的影响

### 7.3 日志级别调整

如需调整特定包的日志级别，可编辑对应模块的 `logback-spring.xml` 文件，取消注释并修改以下配置：

```xml
<!-- 示例：将订单服务的日志级别调整为 DEBUG -->
<logger name="com.example.order" level="DEBUG"/>
```

常用日志级别：
- `TRACE`: 最详细的追踪信息
- `DEBUG`: 调试信息（开发环境推荐）
- `INFO`: 一般信息（生产环境默认）
- `WARN`: 警告信息
- `ERROR`: 错误信息

### 7.4 查看日志

**实时查看日志：**
```bash
# 查看订单服务实时日志
tail -f logs/trace-order.log

# 仅查看错误日志
tail -f logs/trace-order-error.log
```

**搜索特定内容：**
```bash
# 搜索包含 "ERROR" 的日志行
grep "ERROR" logs/trace-order.log

# 搜索特定关键词
grep "Order Created" logs/trace-order.log
```

---

## 8. 常见问题排查

### 8.1 端口冲突

确保 8080, 8081, 8082, 11800, 12800, 8088 端口未被占用。

### 8.2 macOS DNS 解析警告

项目已在 pom.xml 中配置了 Netty 版本及 macOS 原生 DNS 解析器依赖 (netty-resolver-dns-native-macos)，以解决 Netty 在 macOS 上的 DNS 解析警告。

### 8.3 404 Not Found

检查 Gateway 路由配置 (GatewayApplication.java) 是否正确。

检查目标服务是否已启动并监听正确端口。

Order 服务启动时会打印注册的 API 端点，请查看控制台日志确认。

### 8.4 SkyWalking 无数据

确认 Docker 容器正常运行: `docker ps`

检查启动命令中的 -Dskywalking.collector.backend_service 地址是否正确 (默认 127.0.0.1:11800)。

查看 Agent 日志: skywalking-agent/logs/skywalking-api.log。

### 8.5 日志文件未生成

- 确认服务已重启（修改日志配置后需要重启才能生效）
- 检查项目根目录下是否存在 `logs/` 文件夹
- 查看控制台是否有 Logback 初始化错误信息
- 确认 `logback-spring.xml` 文件位于 `src/main/resources/` 目录下

---

## 9. Kubernetes 部署（Helm）

本项目支持使用 Helm 在 Kubernetes 集群中部署微服务。Helm 是 Kubernetes 的包管理工具，可以简化应用的部署和管理。

### 9.1 前置条件

- Kubernetes 集群（如 Minikube、Kind 或云厂商提供的 K8s 集群）
- Helm 3.x+
- Docker 镜像已构建并推送到镜像仓库

### 9.2 构建 Docker 镜像

首先为每个服务构建 Docker 镜像：

```bash
# 在项目根目录执行
mvn clean package -DskipTests

# 构建订单服务镜像
docker build -t your-registry/trace-order:1.0.0 -f trace-order/Dockerfile trace-order/

# 构建库存服务镜像
docker build -t your-registry/trace-inventory:1.0.0 -f trace-inventory/Dockerfile trace-inventory/

# 构建网关服务镜像
docker build -t your-registry/trace-gateway:1.0.0 -f trace-gateway/Dockerfile trace-gateway/

# 推送镜像到仓库
docker push your-registry/trace-order:1.0.0
docker push your-registry/trace-inventory:1.0.0
docker push your-registry/trace-gateway:1.0.0
```

**注意**: 需要在每个模块根目录创建 `Dockerfile`（见下方示例）。

### 9.3 创建 Helm Chart

#### 9.3.1 初始化 Chart

```bash
# 在项目根目录创建 Helm Chart
helm create trace-demo
```

这将生成以下目录结构：
```
trace-demo/
├── charts/
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── _helpers.tpl
├── Chart.yaml
├── values.yaml
└── values.schema.json
```

#### 9.3.2 配置 Chart.yaml

编辑 `trace-demo/Chart.yaml`：

```yaml
apiVersion: v2
name: trace-demo
description: A Helm chart for Trace Demo microservices
type: application
version: 0.1.0
appVersion: "1.0.0"
```

#### 9.3.3 配置 values.yaml

编辑 `trace-demo/values.yaml`，定义各服务的配置：

```yaml
# 全局配置
global:
  imageRegistry: your-registry
  imagePullPolicy: IfNotPresent
  skywalking:
    enabled: true
    collectorBackendService: "skywalking-oap:11800"

# 网关服务配置
gateway:
  replicaCount: 1
  image:
    repository: trace-gateway
    tag: "1.0.0"
  service:
    type: ClusterIP
    port: 8080
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi

# 订单服务配置
order:
  replicaCount: 2
  image:
    repository: trace-order
    tag: "1.0.0"
  service:
    type: ClusterIP
    port: 8081
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi

# 库存服务配置
inventory:
  replicaCount: 2
  image:
    repository: trace-inventory
    tag: "1.0.0"
  service:
    type: ClusterIP
    port: 8082
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi
```

#### 9.3.4 创建 Deployment 模板

在 `trace-demo/templates/` 目录下为每个服务创建 Deployment 和 Service 模板。

**示例：templates/gateway-deployment.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "trace-demo.fullname" . }}-gateway
  labels:
    {{- include "trace-demo.labels" . | nindent 4 }}
    app: gateway
spec:
  replicas: {{ .Values.gateway.replicaCount }}
  selector:
    matchLabels:
      {{- include "trace-demo.selectorLabels" . | nindent 6 }}
      app: gateway
  template:
    metadata:
      labels:
        {{- include "trace-demo.selectorLabels" . | nindent 8 }}
        app: gateway
    spec:
      containers:
        - name: gateway
          image: "{{ .Values.global.imageRegistry }}/{{ .Values.gateway.image.repository }}:{{ .Values.gateway.image.tag }}"
          imagePullPolicy: {{ .Values.global.imagePullPolicy }}
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          {{- if .Values.global.skywalking.enabled }}
          env:
            - name: JAVA_TOOL_OPTIONS
              value: "-javaagent:/skywalking-agent/skywalking-agent.jar"
            - name: SW_AGENT_NAME
              value: "trace-gateway"
            - name: SW_AGENT_COLLECTOR_BACKEND_SERVICES
              value: {{ .Values.global.skywalking.collectorBackendService | quote }}
          {{- end }}
          resources:
            {{- toYaml .Values.gateway.resources | nindent 12 }}
```

**示例：templates/gateway-service.yaml**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "trace-demo.fullname" . }}-gateway
  labels:
    {{- include "trace-demo.labels" . | nindent 4 }}
    app: gateway
spec:
  type: {{ .Values.gateway.service.type }}
  ports:
    - port: {{ .Values.gateway.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "trace-demo.selectorLabels" . | nindent 4 }}
    app: gateway
```

类似地，为 `order` 和 `inventory` 服务创建对应的 Deployment 和 Service 模板。

### 9.4 Dockerfile 示例

在每个服务模块根目录创建 `Dockerfile`：

**trace-order/Dockerfile**

```dockerfile
FROM openjdk:8-jre-slim

# 安装 SkyWalking Agent（可选）
ARG SKYWALKING_VERSION=9.0.0
RUN apt-get update && apt-get install -y wget \
    && wget https://archive.apache.org/dist/skywalking/${SKYWALKING_VERSION}/apache-skywalking-apm-${SKYWALKING_VERSION}.tar.gz \
    && tar -xzf apache-skywalking-apm-${SKYWALKING_VERSION}.tar.gz \
    && mv apache-skywalking-apm-bin /skywalking-agent \
    && rm -rf apache-skywalking-apm-${SKYWALKING_VERSION}.tar.gz

WORKDIR /app
COPY target/trace-order-1.0.0.jar app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 9.5 部署应用

#### 9.5.1 安装 Helm Chart

```bash
# 添加 Helm 仓库（如果使用外部 Chart）
# helm repo add myrepo https://my-chart-repo/

# 安装 Chart
helm install trace-demo ./trace-demo \
  --namespace trace-demo \
  --create-namespace

# 或者自定义配置
helm install trace-demo ./trace-demo \
  --namespace trace-demo \
  --set global.imageRegistry=my-registry.com \
  --set gateway.replicaCount=2
```

#### 9.5.2 查看部署状态

```bash
# 查看 Release 状态
helm status trace-demo -n trace-demo

# 查看 Pod 状态
kubectl get pods -n trace-demo

# 查看 Service
kubectl get svc -n trace-demo
```

#### 9.5.3 访问应用

```bash
# 端口转发访问网关
kubectl port-forward svc/trace-demo-gateway 8080:8080 -n trace-demo

# 测试接口
curl http://localhost:8080/order/create
```

### 9.6 升级和回滚

#### 9.6.1 升级应用

```bash
# 修改 values.yaml 后升级
helm upgrade trace-demo ./trace-demo -n trace-demo

# 或者直接设置参数
helm upgrade trace-demo ./trace-demo \
  -n trace-demo \
  --set order.replicaCount=3
```

#### 9.6.2 回滚版本

```bash
# 查看历史版本
helm history trace-demo -n trace-demo

# 回滚到指定版本
helm rollback trace-demo 1 -n trace-demo
```

### 9.7 卸载应用

```bash
# 卸载 Release
helm uninstall trace-demo -n trace-demo

# 删除命名空间
kubectl delete namespace trace-demo
```

### 9.8 集成 SkyWalking

如果启用了 SkyWalking，需要先部署 SkyWalking：

```bash
# 添加 SkyWalking Helm 仓库
helm repo add skywalking https://apache.jfrog.io/artifactory/skywalking-helm

# 部署 SkyWalking OAP 和 UI
helm install skywalking skywalking/skywalking \
  -n skywalking \
  --create-namespace \
  --set oap.replicas=1 \
  --set ui.service.type=NodePort

# 然后部署应用时启用 SkyWalking
helm install trace-demo ./trace-demo \
  -n trace-demo \
  --set global.skywalking.enabled=true \
  --set global.skywalking.collectorBackendService="skywalking-oap.skywalking:11800"
```

### 9.9 在 K8s 中保留应用原始日志

在 Kubernetes 环境中，容器重启后日志会丢失。为了保留应用的原始日志文件（如 `logs/trace-order.log`），可以采用以下方案：

#### 方案一（推荐）：PersistentVolume + Fluent-bit Sidecar（原始日志保留 + 集中化存储）

这是**生产环境最佳实践**，既能保留原始日志文件，又能实现集中化管理和分析。

**架构说明：**
```
┌─────────────────────────────────────────────┐
│  Pod                                        │
│  ┌──────────────┐    ┌──────────────────┐   │
│  │ App Container│    │ Fluent-bit       │   │
│  │              │    │ Sidecar          │   │
│  │ /app/logs/   │◄──►│ /var/log/app/    │   │
│  │ *.log 文件   │    │                  │   │
│  └──────┬───────┘    └────────┬─────────┘   │
│         │                     │              │
└─────────┼─────────────────────┼──────────────┘
          │                     │
          ▼                     ▼
   ┌──────────────┐    ┌──────────────┐
   │ Persistent   │    │ Elasticsearch│
   │ Volume (PV)  │    │ or Loki      │
   │ 原始日志文件  │    │ 集中化存储    │
   └──────────────┘    └──────────────┘
```

**优势：**
- ✅ **保留原始文本文件**：在 PV 中持久化存储 `.log` 文件
- ✅ **集中化管理**：Fluent-bit 实时收集日志到 ES/Loki
- ✅ **Pod 重启不丢失**：PV 保证日志文件永久保存
- ✅ **双重保障**：既有原始文件备份，又有集中化分析能力

**步骤 1: 修改 values.yaml**

```yaml
# 全局配置
global:
  imageRegistry: your-registry
  environment: production
  
# 订单服务配置
order:
  replicaCount: 2
  image:
    repository: trace-order
    tag: "1.0.0"
  service:
    type: ClusterIP
    port: 8081
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi
  # 日志卷配置 - 使用 PersistentVolume
  logVolume:
    enabled: true
    size: 10Gi  # 根据日志量调整
    storageClassName: standard  # 根据你的集群调整
    accessMode: ReadWriteOnce

# Fluent-bit 配置
fluentbit:
  enabled: true
  image:
    repository: fluent/fluent-bit
    tag: "2.1.8"
  resources:
    limits:
      cpu: 200m
      memory: 200Mi
    requests:
      cpu: 100m
      memory: 100Mi
  # 输出配置 - 集中化存储
  output:
    type: elasticsearch  # 或 loki
    elasticsearch:
      host: "elasticsearch.elasticsearch.svc.cluster.local"
      port: 9200
      index: "trace-demo-logs"
      username: ""  # 如果需要认证
      password: ""  # 如果需要认证
    loki:
      url: "http://loki.monitoring:3100/loki/api/v1/push"
  # 日志处理配置
  config:
    flushInterval: 5  # 刷新间隔（秒）
    logLevel: info
    memBufLimit: 5MB
    multilineFlush: 4  # 多行日志合并等待时间
```

**步骤 2: 创建 PersistentVolumeClaim 模板**

创建 `templates/order-pvc.yaml`：

```
{{- if .Values.order.logVolume.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "trace-demo.fullname" . }}-order-logs
  labels:
    {{- include "trace-demo.labels" . | nindent 4 }}
    app: order
spec:
  accessModes:
    - {{ .Values.order.logVolume.accessMode | default "ReadWriteOnce" }}
  resources:
    requests:
      storage: {{ .Values.order.logVolume.size | default "10Gi" }}
  {{- if .Values.order.logVolume.storageClassName }}
  storageClassName: {{ .Values.order.logVolume.storageClassName }}
  {{- end }}
{{- end }}
```

同样为 gateway 和 inventory 创建对应的 PVC 模板。

**步骤 3: 创建 Fluent-bit ConfigMap（增强版）**

创建 `templates/fluentbit-config.yaml`：

```
{{- if .Values.fluentbit.enabled }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "trace-demo.fullname" . }}-fluentbit-config
  labels:
    {{- include "trace-demo.labels" . | nindent 4 }}
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush         {{ .Values.fluentbit.config.flushInterval }}
        Log_Level     {{ .Values.fluentbit.config.logLevel }}
        Daemon        off
        Parsers_File  parsers.conf
        HTTP_Server   On
        HTTP_Listen   0.0.0.0
        HTTP_Port     2020
        Storage_Path  /var/log/flb-storage

    @INCLUDE input-kubernetes.conf
    @INCLUDE filter-kubernetes.conf
    @INCLUDE output-{{ .Values.fluentbit.output.type }}.conf

  input-kubernetes.conf: |
    [INPUT]
        Name              tail
        Tag               kube.*
        Path              /var/log/app/*.log
        Parser_Firstline  logback_multiline
        Parser_1          logback
        DB                /var/log/flb_kube.db
        Mem_Buf_Limit     {{ .Values.fluentbit.config.memBufLimit }}
        Skip_Long_Lines   On
        Refresh_Interval  10
        Rotate_Wait       30
        storage.type      filesystem
        Read_from_Head    Off
        Multiline         On
        Multiline_Flush   {{ .Values.fluentbit.config.multilineFlush }}

  filter-kubernetes.conf: |
    [FILTER]
        Name                kubernetes
        Match               kube.*
        Kube_URL            https://kubernetes.default.svc:443
        Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
        Merge_Log           On
        Keep_Log            Off
        K8S-Logging.Parser  On
        K8S-Logging.Exclude On

    [FILTER]
        Name                record_modifier
        Match               *
        Record              cluster_name trace-demo
        Record              environment {{ .Values.global.environment | default "production" }}

  output-elasticsearch.conf: |
    [OUTPUT]
        Name            es
        Match           *
        Host            {{ .Values.fluentbit.output.elasticsearch.host }}
        Port            {{ .Values.fluentbit.output.elasticsearch.port }}
        Index           {{ .Values.fluentbit.output.elasticsearch.index }}
        Type            _doc
        Replace_Dots    On
        Retry_Limit     False
        Logstash_Format On
        Logstash_Prefix trace-demo
        Time_Key        @timestamp
        Time_Key_Format %Y-%m-%dT%H:%M:%S
        {{- if .Values.fluentbit.output.elasticsearch.username }}
        HTTP_User       {{ .Values.fluentbit.output.elasticsearch.username }}
        HTTP_Passwd     {{ .Values.fluentbit.output.elasticsearch.password }}
        {{- end }}
        Suppress_Type_Name On

    [OUTPUT]
        Name            stdout
        Match           *
        Format          json

  output-loki.conf: |
    [OUTPUT]
        Name            loki
        Match           *
        Url             {{ .Values.fluentbit.output.loki.url }}
        Labels          job=trace-demo-logs,cluster=trace-demo,environment={{ .Values.global.environment }}
        Label_Keys      $kubernetes['namespace_name'],$kubernetes['pod_name'],$kubernetes['container_name']
        Line_Format     json
        Auto_Kubernetes_Labels on
        Remove_keys     kubernetes

  parsers.conf: |
    [PARSER]
        Name        docker
        Format      json
        Time_Key    time
        Time_Format %Y-%m-%dT%H:%M:%S.%L
        Time_Keep   On

    [PARSER]
        Name        logback_multiline
        Format      regex
        Regex       ^(?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}) \[(?<thread>[^\]]+)\] (?<level>\w+) (?<logger>\S+) - (?<message>.*)
        Time_Key    time
        Time_Format %Y-%m-%d %H:%M:%S.%L

    [PARSER]
        Name        logback
        Format      regex
        Regex       ^(?<message>.*)
{{- end }}
```

**步骤 4: 修改 Deployment 模板**

在 `templates/order-deployment.yaml` 中：

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "trace-demo.fullname" . }}-order
  labels:
    {{- include "trace-demo.labels" . | nindent 4 }}
    app: order
spec:
  replicas: {{ .Values.order.replicaCount }}
  selector:
    matchLabels:
      {{- include "trace-demo.selectorLabels" . | nindent 6 }}
      app: order
  template:
    metadata:
      labels:
        {{- include "trace-demo.selectorLabels" . | nindent 8 }}
        app: order
    spec:
      volumes:
        # 持久化日志卷 - 保留原始文件
        - name: log-volume
          persistentVolumeClaim:
            claimName: {{ include "trace-demo.fullname" . }}-order-logs
        # Fluent-bit 配置卷
        {{- if .Values.fluentbit.enabled }}
        - name: fluentbit-config
          configMap:
            name: {{ include "trace-demo.fullname" . }}-fluentbit-config
        - name: fluentbit-position
          emptyDir: {}
        - name: fluentbit-storage
          emptyDir: {}
        {{- end }}
      containers:
        # 应用容器
        - name: order
          image: "{{ .Values.global.imageRegistry }}/{{ .Values.order.image.repository }}:{{ .Values.order.image.tag }}"
          imagePullPolicy: {{ .Values.global.imagePullPolicy }}
          ports:
            - name: http
              containerPort: 8081
              protocol: TCP
          volumeMounts:
            - name: log-volume
              mountPath: /app/logs
          {{- if .Values.global.skywalking.enabled }}
          env:
            - name: JAVA_TOOL_OPTIONS
              value: "-javaagent:/skywalking-agent/skywalking-agent.jar"
            - name: SW_AGENT_NAME
              value: "trace-order"
            - name: SW_AGENT_COLLECTOR_BACKEND_SERVICES
              value: {{ .Values.global.skywalking.collectorBackendService | quote }}
          {{- end }}
          resources:
            {{- toYaml .Values.order.resources | nindent 12 }}
          livenessProbe:
            httpGet:
              path: /order/health
              port: 8081
            initialDelaySeconds: 60
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /order/health
              port: 8081
            initialDelaySeconds: 30
            periodSeconds: 5
          
        # Fluent-bit Sidecar - 集中化日志收集
        {{- if .Values.fluentbit.enabled }}
        - name: fluent-bit
          image: "{{ .Values.fluentbit.image.repository }}:{{ .Values.fluentbit.image.tag }}"
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 2020
              protocol: TCP
          volumeMounts:
            # 挂载相同的日志卷，读取原始文件
            - name: log-volume
              mountPath: /var/log/app
              readOnly: true
            - name: fluentbit-config
              mountPath: /fluent-bit/etc/
            - name: fluentbit-position
              mountPath: /var/log/
            - name: fluentbit-storage
              mountPath: /var/log/flb-storage
          resources:
            {{- toYaml .Values.fluentbit.resources | nindent 12 }}
          readinessProbe:
            httpGet:
              path: /
              port: 2020
            initialDelaySeconds: 10
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /
              port: 2020
            initialDelaySeconds: 30
            periodSeconds: 30
        {{- end }}
```

**步骤 5: 部署 Elasticsearch 或 Loki**

**选项 A：部署 Elasticsearch（功能强大）**

```bash
# 添加 Elastic Helm 仓库
helm repo add elastic https://helm.elastic.co

# 部署 Elasticsearch
helm install elasticsearch elastic/elasticsearch \
  -n elasticsearch \
  --create-namespace \
  --set replicas=1 \
  --set minimumMasterNodes=1 \
  --set persistence.enabled=true \
  --set persistence.size=50Gi

# 部署 Kibana
helm install kibana elastic/kibana \
  -n elasticsearch \
  --set elasticsearchHosts=http://elasticsearch-master:9200
```

**选项 B：部署 Loki（轻量级）**

```bash
# 添加 Grafana Helm 仓库
helm repo add grafana https://grafana.github.io/helm-charts

# 部署 Loki Stack
helm install loki-stack grafana/loki-stack \
  -n monitoring \
  --create-namespace \
  --set promtail.enabled=false \  # 我们使用自己的 Fluent-bit
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=50Gi \
  --set grafana.enabled=true \
  --set grafana.persistence.enabled=true
```

**步骤 6: 部署应用**

```bash
# 部署应用
helm install trace-demo ./trace-demo \
  -n trace-demo \
  --create-namespace \
  --set global.imageRegistry=your-registry.com \
  --set fluentbit.output.type=elasticsearch \
  --set fluentbit.output.elasticsearch.host=elasticsearch-master.elasticsearch.svc.cluster.local
```

#### 方案二：仅使用 PersistentVolume（仅保留原始文件，无集中化）

**步骤 1: 修改 values.yaml**

```
# 全局配置
global:
  imageRegistry: your-registry
  environment: production
  
# 订单服务配置
order:
  replicaCount: 2
  image:
    repository: trace-order
    tag: "1.0.0"
  service:
    type: ClusterIP
    port: 8081
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi
  # 日志卷配置 - 使用 PersistentVolume
  logVolume:
    enabled: true
    size: 10Gi  # 根据日志量调整
    storageClassName: standard  # 根据你的集群调整
    accessMode: ReadWriteOnce

```

**步骤 2: 创建 PersistentVolumeClaim 模板**

创建 `templates/order-pvc.yaml`：

```
{{- if .Values.order.logVolume.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "trace-demo.fullname" . }}-order-logs
  labels:
    {{- include "trace-demo.labels" . | nindent 4 }}
    app: order
spec:
  accessModes:
    - {{ .Values.order.logVolume.accessMode | default "ReadWriteOnce" }}
  resources:
    requests:
      storage: {{ .Values.order.logVolume.size | default "10Gi" }}
  {{- if .Values.order.logVolume.storageClassName }}
  storageClassName: {{ .Values.order.logVolume.storageClassName }}
  {{- end }}
{{- end }}
```

同样为 gateway 和 inventory 创建对应的 PVC 模板。

**步骤 3: 修改 Deployment 模板**

在 `templates/order-deployment.yaml` 中：

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "trace-demo.fullname" . }}-order
  labels:
    {{- include "trace-demo.labels" . | nindent 4 }}
    app: order
spec:
  replicas: {{ .Values.order.replicaCount }}
  selector:
    matchLabels:
      {{- include "trace-demo.selectorLabels" . | nindent 6 }}
      app: order
  template:
    metadata:
      labels:
        {{- include "trace-demo.selectorLabels" . | nindent 8 }}
        app: order
    spec:
      volumes:
        - name: log-volume
          persistentVolumeClaim:
            claimName: {{ include "trace-demo.fullname" . }}-order-logs
      containers:
        - name: order
          image: "{{ .Values.global.imageRegistry }}/{{ .Values.order.image.repository }}:{{ .Values.order.image.tag }}"
          imagePullPolicy: {{ .Values.global.imagePullPolicy }}
          ports:
            - name: http
              containerPort: 8081
              protocol: TCP
          {{- if .Values.global.skywalking.enabled }}
          env:
            - name: JAVA_TOOL_OPTIONS
              value: "-javaagent:/skywalking-agent/skywalking-agent.jar"
            - name: SW_AGENT_NAME
              value: "trace-order"
            - name: SW_AGENT_COLLECTOR_BACKEND_SERVICES
              value: {{ .Values.global.skywalking.collectorBackendService | quote }}
          {{- end }}
          resources:
            {{- toYaml .Values.order.resources | nindent 12 }}
          livenessProbe:
            httpGet:
              path: /order/health
              port: 8081
            initialDelaySeconds: 60
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /order/health
              port: 8081
            initialDelaySeconds: 30
            periodSeconds: 5
```

### 9.9.1 访问和管理原始日志文件

使用 PersistentVolume 方案后，你可以通过以下方式访问原始的 `.log` 文本文件：

#### **方法 1：通过临时 Pod 挂载 PV 访问**

创建一个临时 Pod 来访问日志文件：

```bash
# 创建临时 Pod 挂载 PVC
kubectl run log-access --rm -i --tty \
  --image=busybox \
  --restart=Never \
  --overrides='{
    "spec": {
      "volumes": [{
        "name": "logs",
        "persistentVolumeClaim": {
          "claimName": "trace-demo-order-logs"
        }
      }],
      "containers": [{
        "name": "access",
        "image": "busybox",
        "command": ["sh"],
        "stdin": true,
        "tty": true,
        "volumeMounts": [{
          "name": "logs",
          "mountPath": "/logs"
        }]
      }]
    }
  }' -n trace-demo

# 在 Pod 内执行
ls -lh /logs/
cat /logs/trace-order.log
tail -f /logs/trace-order.log
grep "ERROR" /logs/trace-order-error.log
```

#### **方法 2：使用 kubectl cp 复制日志文件**

```bash
# 从运行中的 Pod 复制日志文件到本地
kubectl cp trace-demo/order-pod-name:/app/logs/trace-order.log ./trace-order.log -n trace-demo

# 复制整个日志目录
kubectl cp trace-demo/order-pod-name:/app/logs/ ./logs/ -n trace-demo

# 查看日志文件列表
kubectl exec -it deployment/trace-demo-order -n trace-demo -- ls -lh /app/logs/
```

#### **方法 3：创建专用的日志访问服务**

创建 `templates/log-viewer.yaml`：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "trace-demo.fullname" . }}-log-viewer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: log-viewer
  template:
    metadata:
      labels:
        app: log-viewer
    spec:
      volumes:
        - name: order-logs
          persistentVolumeClaim:
            claimName: {{ include "trace-demo.fullname" . }}-order-logs
        - name: gateway-logs
          persistentVolumeClaim:
            claimName: {{ include "trace-demo.fullname" . }}-gateway-logs
        - name: inventory-logs
          persistentVolumeClaim:
            claimName: {{ include "trace-demo.fullname" . }}-inventory-logs
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
          volumeMounts:
            - name: order-logs
              mountPath: /usr/share/nginx/html/order
              readOnly: true
            - name: gateway-logs
              mountPath: /usr/share/nginx/html/gateway
              readOnly: true
            - name: inventory-logs
              mountPath: /usr/share/nginx/html/inventory
              readOnly: true
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "trace-demo.fullname" . }}-log-viewer
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: log-viewer
```

部署后访问：
```bash
kubectl port-forward svc/trace-demo-log-viewer 8080:80 -n trace-demo
# 浏览器访问 http://localhost:8080/order/trace-order.log
```

#### **方法 4：使用 NFS 或云存储直接访问**

如果使用 NFS 或云厂商的存储服务（如 AWS EFS、阿里云 NAS），可以直接挂载到管理节点：

```bash
# NFS 示例
sudo mount -t nfs <nfs-server>:/path/to/pv /mnt/logs

# 直接访问
ls -lh /mnt/logs/
tail -f /mnt/logs/trace-order.log
```

#### **方法 5：定期备份日志文件**

创建 CronJob 定期备份日志到对象存储：

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ include "trace-demo.fullname" . }}-log-backup
spec:
  schedule: "0 2 * * *"  # 每天凌晨2点
  jobTemplate:
    spec:
      template:
        spec:
          volumes:
            - name: order-logs
              persistentVolumeClaim:
                claimName: {{ include "trace-demo.fullname" . }}-order-logs
            - name: backup-storage
              emptyDir: {}
          containers:
            - name: backup
              image: amazon/aws-cli  # 或使用阿里云 ossutil
              command:
                - /bin/sh
                - -c
                - |
                  # 压缩日志文件
                  tar -czf /backup/trace-order-$(date +%Y%m%d).tar.gz -C /logs .
                  
                  # 上传到 S3
                  aws s3 cp /backup/trace-order-$(date +%Y%m%d).tar.gz \
                    s3://my-log-bucket/trace-demo/$(date +%Y%m%d)/
              volumeMounts:
                - name: order-logs
                  mountPath: /logs
                  readOnly: true
                - name: backup-storage
                  mountPath: /backup
              env:
                - name: AWS_ACCESS_KEY_ID
                  valueFrom:
                    secretKeyRef:
                      name: aws-credentials
                      key: access-key-id
                - name: AWS_SECRET_ACCESS_KEY
                  valueFrom:
                    secretKeyRef:
                      name: aws-credentials
                      key: secret-access-key
          restartPolicy: OnFailure
```

### 9.9.2 集中化日志查询和分析

#### **Elasticsearch + Kibana**

**访问 Kibana：**
```bash
kubectl port-forward svc/kibana-kibana 5601:5601 -n elasticsearch
# 浏览器访问 http://localhost:5601
```

**常用查询示例：**
``kql
// 查询错误日志
level: ERROR

// 查询特定服务
kubernetes.container_name: order

// 查询最近1小时的日志
@timestamp >= now-1h

// 组合查询
kubernetes.container_name: order AND level: ERROR AND message: "Exception"

// 统计各服务错误数量
level: ERROR
// 然后在 Visualize 中创建条形图，按 kubernetes.container_name 分组
```

**创建告警规则：**
1. 进入 Stack Management > Watcher
2. 创建新的 Watch
3. 配置触发条件：5分钟内 ERROR 日志超过 10 条
4. 设置通知方式（邮件、Slack、Webhook）

#### **Grafana + Loki**

**访问 Grafana：**
```bash
kubectl port-forward svc/loki-stack-grafana 3000:80 -n monitoring
# 浏览器访问 http://localhost:3000
# 默认账号密码: admin/prom-operator
```

**LogQL 查询示例：**
``logql
// 查询所有日志
{job="trace-demo-logs"}

// 查询错误日志
{job="trace-demo-logs"} |= "ERROR"

// 查询订单服务的异常
{kubernetes_container_name="order"} |= "Exception"

// 统计各服务日志量
sum by (kubernetes_container_name) (count_over_time({job="trace-demo-logs"}[1h]))

// 提取日志中的关键信息
{kubernetes_container_name="order"} | pattern `<time> [<level>] <msg>`

// 多行日志查询（Java 异常堆栈）
{kubernetes_container_name="order"} |= "Exception" | line_format "{{.message}}"
```

**创建 Grafana Dashboard：**
1. 新建 Dashboard
2. 添加 Panel，选择 Loki 数据源
3. 输入 LogQL 查询
4. 设置可视化类型（Logs、Time series、Stat 等）
5. 保存并分享 Dashboard

### 9.9.3 日志生命周期管理

#### **应用层日志滚动（logback-spring.xml）**

确保应用配置的滚动策略适合持久化存储：

```xml
<rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
    <!-- 每个文件最大 100MB -->
    <maxFileSize>100MB</maxFileSize>
    <!-- 保留 30 天的日志 -->
    <maxHistory>30</maxHistory>
    <!-- 总大小限制为 10GB（根据 PV 大小调整） -->
    <totalSizeCap>10GB</totalSizeCap>
    <fileNamePattern>/app/logs/trace-order.%d{yyyy-MM-dd}.%i.log</fileNamePattern>
</rollingPolicy>
```

#### **Elasticsearch ILM（索引生命周期管理）**

创建 ILM 策略自动清理旧日志：

```json
PUT _ilm/policy/trace-demo-logs-policy
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_age": "1d",
            "max_size": "10gb"
          }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "shrink": {
            "number_of_shards": 1
          },
          "forcemerge": {
            "max_num_segments": 1
          }
        }
      },
      "delete": {
        "min_age": "30d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

#### **Loki 日志保留策略**

在 Loki 配置中设置保留时间：

```yaml
# values.yaml
loki:
  config:
    limits_config:
      retention_period: 720h  # 30天
    
  retention_deletes_enabled: true
  retention_period: 720h
```

### 9.10 监控和告警

#### **Fluent-bit 监控指标**

Fluent-bit 提供 Prometheus 格式的监控指标：

```bash
# 端口转发访问指标
kubectl port-forward deployment/trace-demo-order 2020:2020 -n trace-demo

# 查看指标
curl http://localhost:2020/api/v1/metrics/prometheus
```

**关键指标：**
- `fluentbit_input_records_total`: 读取的日志总数
- `fluentbit_output_errors_total`: 输出错误数
- `fluentbit_output_proc_records_total`: 处理的记录数
- `fluentbit_storage_backlog_size`:  backlog 大小

**Prometheus + Grafana 监控面板：**
```yaml
# prometheus-rule.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: fluentbit-alerts
spec:
  groups:
    - name: fluentbit
      rules:
        - alert: FluentBitHighErrorRate
          expr: rate(fluentbit_output_errors_total[5m]) > 10
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "Fluent-bit 错误率过高"
            description: "过去5分钟错误率: {{ $value }}/秒"
        
        - alert: FluentBitBacklogGrowing
          expr: fluentbit_storage_backlog_size > 1000
          for: 10m
          labels:
            severity: critical
          annotations:
            summary: "Fluent-bit Backlog 持续增长"
            description: "Backlog 大小: {{ $value }}"
```

### 9.11 最佳实践总结

1. **双重保障架构**：PersistentVolume（原始文件）+ Fluent-bit（集中化）= 最可靠方案
2. **资源规划**：
   - PV 大小：根据日志产生速率 × 保留天数 × 冗余系数（建议 2-3 倍）
   - Fluent-bit：CPU 100-200m，内存 100-200Mi
   - Elasticsearch：根据日志量和查询需求规划（通常 50Gi 起步）
3. **日志分级存储**：ERROR/WARN 单独索引，便于快速检索和告警
4. **多行日志处理**：Java 异常堆栈必须配置 multiline 解析器
5. **敏感信息脱敏**：在 Fluent-bit 过滤器中脱敏或使用应用层脱敏
6. **监控告警**：监控 Fluent-bit 健康状态、错误率、backlog 大小
7. **生命周期管理**：应用层滚动 + 存储层 ILM/retention，避免磁盘爆满
8. **定期备份**：重要日志定期备份到对象存储（S3/OSS）
9. **性能优化**：
   - 调整 `flushInterval` 平衡实时性和吞吐量
   - 启用 `storage.type filesystem` 防止内存溢出
   - 合理设置 `memBufLimit`
10. **灾难恢复**：保留原始文件是最后的保障，即使集中化系统故障也能追溯
