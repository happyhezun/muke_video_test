# Trace Demo Helm Charts - 完整部署指南

## 📦 项目概述

本项目为 **Trace Demo** 微服务系统提供了完整的 Helm Chart，支持在 Kubernetes 集群中一键部署所有服务。

### 包含的服务

1. **trace-order** - 订单服务 (端口 8081)
2. **trace-inventory** - 库存服务 (端口 8082)
3. **trace-gateway** - API网关服务 (端口 8080)

---

## 🚀 快速开始

### 前置条件

- Kubernetes 集群 (v1.19+)
- Helm 3.x+
- Docker 镜像已构建并推送到镜像仓库

### 一键部署所有服务

```bash
# 开发环境
./deploy-all.sh -i -s all -e dev

# 生产环境
./deploy-all.sh -i -s all -e prod

# 查看状态
./deploy-all.sh -st -s all
```

### 部署单个服务

```bash
# 只部署订单服务
./deploy-all.sh -i -s order -e dev

# 只部署网关服务
./deploy-all.sh -i -s gateway -e prod

# 升级库存服务
./deploy-all.sh -u -s inventory -e test
```

---

## 📁 Chart 结构

```
helm/
├── trace-order/              # 订单服务 Chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-prod.yaml
│   ├── README.md
│   └── templates/
├── trace-inventory/          # 库存服务 Chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-prod.yaml
│   ├── README.md
│   └── templates/
└── trace-gateway/            # 网关服务 Chart
    ├── Chart.yaml
    ├── values.yaml
    ├── values-dev.yaml
    ├── values-prod.yaml
    ├── README.md
    └── templates/
```

每个 Chart 都包含以下 Kubernetes 资源模板：
- Deployment
- Service
- ConfigMap
- PVC (日志持久化)
- Ingress (可选)
- HPA (自动扩缩容)
- ServiceAccount
- PDB (Pod中断预算)

---

## ⚙️ 配置说明

### 服务端口映射

| 服务 | 容器端口 | Service端口 | 健康检查路径 |
|------|---------|------------|-------------|
| Order | 8081 | 8081 | `/order/health` |
| Inventory | 8082 | 8082 | `/inventory/health` |
| Gateway | 8080 | 8080 | `/health` |

### 核心配置项

#### 通用配置

```yaml
replicaCount: 1                    # 副本数量
image:
  repository: trace-order          # 镜像名称
  tag: "1.0.0"                     # 镜像标签
  pullPolicy: IfNotPresent         # 拉取策略

service:
  type: ClusterIP                  # 服务类型
  port: 8081                       # 服务端口

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

env:
  - name: SPRING_PROFILES_ACTIVE
    value: "dev"                   # 环境标识
```

#### SkyWalking 配置

```yaml
skywalking:
  enabled: true
  collectorBackendService: "skywalking-oap.skywalking:11800"
  serviceName: "trace-order-dev"
```

#### 自动扩缩容

```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

---

## 🌍 多环境配置

### 开发环境 (dev)

特点：
- 单副本运行
- DEBUG 日志级别
- 本地 SkyWalking
- 较小的资源限制

```bash
./deploy-all.sh -i -s all -e dev
```

### 测试环境 (test)

特点：
- 2个副本
- INFO 日志级别
- 测试 SkyWalking
- 标准资源限制

```bash
./deploy-all.sh -i -s all -e test
```

### 生产环境 (prod)

特点：
- 3+ 副本 + HPA
- WARN 日志级别
- 生产 SkyWalking
- 高资源限制
- 启用 PDB
- LoadBalancer 服务类型（网关）

```bash
./deploy-all.sh -i -s all -e prod
```

---

## 🔧 常用操作

### 安装服务

```bash
# 安装所有服务
./deploy-all.sh -i -s all -e dev

# 安装单个服务
./deploy-all.sh -i -s order -e dev
```

### 升级服务

```bash
# 升级所有服务
./deploy-all.sh -u -s all -e prod

# 升级单个服务
./deploy-all.sh -u -s gateway -e prod
```

### 卸载服务

```bash
# 卸载所有服务
./deploy-all.sh -d -s all

# 卸载单个服务
./deploy-all.sh -d -s order
```

### 查看状态

```bash
# 查看所有服务状态
./deploy-all.sh -st -s all

# 查看单个服务状态
./deploy-all.sh -st -s gateway
```

### 使用原生 Helm 命令

```bash
# 安装
helm install trace-order ./helm/trace-order \
  --namespace trace-demo \
  --create-namespace \
  -f helm/trace-order/values-dev.yaml

# 升级
helm upgrade trace-order ./helm/trace-order \
  --namespace trace-demo \
  -f helm/trace-order/values-prod.yaml

# 回滚
helm rollback trace-order 1 -n trace-demo

# 卸载
helm uninstall trace-order -n trace-demo

# 查看历史
helm history trace-order -n trace-demo
```

---

## 📊 验证部署

### 检查 Pod 状态

```bash
kubectl get pods -n trace-demo
```

预期输出：
```
NAME                              READY   STATUS    RESTARTS   AGE
trace-inventory-xxxxx            1/1     Running   0          2m
trace-order-xxxxx                1/1     Running   0          2m
trace-gateway-xxxxx              1/1     Running   0          2m
```

### 检查服务

```bash
kubectl get svc -n trace-demo
```

预期输出：
```
NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
trace-inventory   ClusterIP   10.96.xxx.xxx   <none>        8082/TCP   2m
trace-order       ClusterIP   10.96.xxx.xxx   <none>        8081/TCP   2m
trace-gateway     ClusterIP   10.96.xxx.xxx   <none>        8080/TCP   2m
```

### 端口转发测试

```bash
# 转发网关服务
kubectl port-forward -n trace-demo svc/trace-gateway 8080:8080

# 在另一个终端测试
curl http://localhost:8080/order/health
curl http://localhost:8080/inventory/health
curl http://localhost:8080/health
```

### 查看日志

```bash
# 查看所有服务日志
kubectl logs -n trace-demo -l app.kubernetes.io/instance=trace-gateway -f

# 查看特定服务日志
kubectl logs -n trace-demo -l app.kubernetes.io/name=trace-order -f
```

---

## 🎯 高级配置

### 使用私有镜像仓库

```yaml
# values-prod.yaml
image:
  repository: your-registry.com/trace-order
  pullPolicy: Always

imagePullSecrets:
  - name: registry-secret
```

创建密钥：
```bash
kubectl create secret docker-registry registry-secret \
  --docker-server=your-registry.com \
  --docker-username=username \
  --docker-password=password \
  --namespace trace-demo
```

### 启用 Ingress

```yaml
# values.yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    kubernetes.io/ingress.class: nginx
  hosts:
    - host: order.example.com
      paths:
        - path: /
          pathType: ImplementationSpecific
```

### 配置资源限制

```yaml
resources:
  limits:
    cpu: 2000m
    memory: 2048Mi
  requests:
    cpu: 1000m
    memory: 1024Mi
```

### 启用日志持久化

```yaml
logVolume:
  enabled: true
  size: 20Gi
  storageClassName: standard
  accessMode: ReadWriteOnce
```

---

## 🐛 故障排查

### Pod 无法启动

```bash
# 查看 Pod 详情
kubectl describe pod -n trace-demo <pod-name>

# 查看事件
kubectl get events -n trace-demo --sort-by='.lastTimestamp'

# 查看日志
kubectl logs -n trace-demo <pod-name> --previous
```

### 服务间调用失败

```bash
# 检查服务发现
kubectl get endpoints -n trace-demo

# 测试连通性
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  wget -qO- http://trace-order:8081/order/health
```

### 配置未生效

```bash
# 检查 ConfigMap
kubectl get configmap -n trace-demo

# 查看 Pod 使用的配置
kubectl get pod -n trace-demo <pod-name> -o yaml | grep -A 10 configMap
```

### 回滚到上一版本

```bash
# 查看历史版本
helm history trace-order -n trace-demo

# 回滚
helm rollback trace-order 1 -n trace-demo
```

---

## 📝 最佳实践

### 1. 部署顺序

始终按照依赖顺序部署：
1. **Inventory Service** (无依赖)
2. **Order Service** (依赖 Inventory)
3. **Gateway Service** (依赖 Order 和 Inventory)

脚本已自动处理此顺序。

### 2. 资源配置

- 开发环境：小资源，单副本
- 测试环境：中等资源，2副本
- 生产环境：大资源，3+副本 + HPA

### 3. 日志管理

- 启用 PVC 持久化日志
- 配合 Fluent-bit Sidecar 收集日志
- 设置合理的日志滚动策略

### 4. 监控告警

- 启用 SkyWalking 分布式追踪
- 集成 Prometheus 监控指标
- 配置 Grafana 可视化面板

### 5. 安全加固

- 使用私有镜像仓库
- 配置 ServiceAccount 最小权限
- 启用 Pod Security Context
- 使用 TLS 加密 Ingress

---

## 🔗 相关文档

- [订单服务 Chart 文档](helm/trace-order/README.md)
- [库存服务 Chart 文档](helm/trace-inventory/README.md)
- [网关服务 Chart 文档](helm/trace-gateway/README.md)
- [环境标识功能说明](ENVIRONMENT_IDENTIFIER.md)
- [多环境配置指南](MULTI_ENV_GUIDE.md)

---

## 🎓 学习资源

- [Helm 官方文档](https://helm.sh/docs/)
- [Kubernetes 官方文档](https://kubernetes.io/docs/)
- [Spring Boot on Kubernetes](https://spring.io/guides/topicals/spring-boot-docker/)
- [SkyWalking Kubernetes](https://skywalking.apache.org/docs/main/latest/en/setup/service-agent/java-agent/readme/#kubernetes)

---

**祝您部署顺利！🚀**
