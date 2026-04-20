# Trace Order Service - Helm 部署指南

## 📋 前置条件

- Kubernetes 集群 (v1.19+)
- Helm 3.x+
- Docker 镜像已构建并推送到镜像仓库

---

## 🚀 快速开始

### 1. 构建 Docker 镜像

```bash
# 进入订单服务目录
cd trace-order

# 构建镜像
docker build -t your-registry/trace-order:1.0.0 .

# 推送镜像到仓库
docker push your-registry/trace-order:1.0.0
```

### 2. 安装 Helm Chart

```bash
# 进入Helm Chart目录
cd helm/trace-order

# 方式一：使用默认配置安装
helm install trace-order . --namespace trace-demo --create-namespace

# 方式二：自定义配置安装
helm install trace-order . \
  --namespace trace-demo \
  --create-namespace \
  --set image.repository=your-registry/trace-order \
  --set image.tag=1.0.0 \
  --set env[0].value=prod

# 方式三：使用values文件安装
helm install trace-order . \
  --namespace trace-demo \
  --create-namespace \
  -f custom-values.yaml
```

### 3. 验证部署

```bash
# 查看Pod状态
kubectl get pods -n trace-demo -l app.kubernetes.io/name=trace-order

# 查看服务
kubectl get svc -n trace-demo -l app.kubernetes.io/name=trace-order

# 查看日志
kubectl logs -n trace-demo -l app.kubernetes.io/name=trace-order -f
```

### 4. 访问服务

```bash
# 端口转发到本地
kubectl port-forward -n trace-demo svc/trace-order 8081:8081

# 健康检查
curl http://localhost:8081/order/health
```

---

## ⚙️ 配置说明

### 核心配置项

| 参数 | 描述 | 默认值 |
|------|------|--------|
| `replicaCount` | 副本数量 | `1` |
| `image.repository` | 镜像仓库地址 | `trace-order` |
| `image.tag` | 镜像标签 | `1.0.0` |
| `service.type` | 服务类型 | `ClusterIP` |
| `service.port` | 服务端口 | `8081` |
| `resources.limits.cpu` | CPU限制 | `500m` |
| `resources.limits.memory` | 内存限制 | `512Mi` |
| `env[0].value` | Spring Profile | `dev` |
| `skywalking.enabled` | 启用SkyWalking | `false` |
| `logVolume.enabled` | 启用日志持久化 | `true` |

### 环境配置示例

#### 开发环境

```yaml
# values-dev.yaml
replicaCount: 1

env:
  - name: SPRING_PROFILES_ACTIVE
    value: "dev"
  - name: JAVA_OPTS
    value: "-Xms256m -Xmx512m"

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

skywalking:
  enabled: true
  collectorBackendService: "skywalking-oap.skywalking:11800"
  serviceName: "trace-order-dev"
```

#### 生产环境

```yaml
# values-prod.yaml
replicaCount: 3

env:
  - name: SPRING_PROFILES_ACTIVE
    value: "prod"
  - name: JAVA_OPTS
    value: "-Xms512m -Xmx1024m"

resources:
  limits:
    cpu: 1000m
    memory: 1024Mi
  requests:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

skywalking:
  enabled: true
  collectorBackendService: "prod-skywalking:11800"
  serviceName: "trace-order-prod"

podDisruptionBudget:
  enabled: true
  minAvailable: 2
```

---

## 🔧 常用操作

### 升级应用

```bash
# 更新配置后升级
helm upgrade trace-order . \
  --namespace trace-demo \
  --set image.tag=1.1.0

# 使用新的values文件升级
helm upgrade trace-order . \
  --namespace trace-demo \
  -f values-prod.yaml
```

### 回滚版本

```bash
# 查看历史版本
helm history trace-order -n trace-demo

# 回滚到指定版本
helm rollback trace-order 1 -n trace-demo
```

### 卸载应用

```bash
# 卸载Release
helm uninstall trace-order -n trace-demo

# 删除命名空间（可选）
kubectl delete namespace trace-demo
```

### 查看状态

```bash
# 查看Release状态
helm status trace-order -n trace-demo

# 查看所有Release
helm list -n trace-demo
```

---

## 🌐 Ingress 配置

如果需要外部访问，可以启用 Ingress：

```yaml
# values-ingress.yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
  hosts:
    - host: order.example.com
      paths:
        - path: /
          pathType: ImplementationSpecific
```

安装时指定：

```bash
helm install trace-order . \
  --namespace trace-demo \
  -f values-ingress.yaml
```

---

## 📊 监控和日志

### 启用 SkyWalking

```yaml
skywalking:
  enabled: true
  agentVersion: "9.0.0"
  collectorBackendService: "skywalking-oap.skywalking:11800"
  serviceName: "trace-order"
```

### 日志持久化

默认已启用日志持久化，日志存储在 PVC 中：

```yaml
logVolume:
  enabled: true
  size: 5Gi
  storageClassName: standard
  accessMode: ReadWriteOnce
```

查看日志：

```bash
# 进入Pod查看日志文件
kubectl exec -it -n trace-demo <pod-name> -- ls -la /app/logs

# 查看实时日志
kubectl exec -it -n trace-demo <pod-name> -- tail -f /app/logs/trace-order.log
```

---

## 🔒 安全配置

### 使用私有镜像仓库

```yaml
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

### Pod 安全上下文

```yaml
podSecurityContext:
  fsGroup: 2000

securityContext:
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
```

---

## 🎯 最佳实践

1. **资源限制**: 始终设置合理的 CPU 和内存限制
2. **健康检查**: 配置 liveness 和 readiness probe
3. **日志管理**: 启用日志持久化，配合日志收集系统
4. **自动扩缩容**: 生产环境启用 HPA
5. **高可用**: 设置 PDB 保证最小可用副本数
6. **配置分离**: 不同环境使用不同的 values 文件
7. **版本管理**: 使用语义化版本号管理镜像标签
8. **监控告警**: 集成 Prometheus + Grafana

---

## 📝 故障排查

### Pod 无法启动

```bash
# 查看Pod详情
kubectl describe pod -n trace-demo <pod-name>

# 查看事件
kubectl get events -n trace-demo --sort-by='.lastTimestamp'

# 查看日志
kubectl logs -n trace-demo <pod-name> --previous
```

### 服务无法访问

```bash
# 检查Service
kubectl get svc -n trace-demo

# 检查Endpoint
kubectl get endpoints -n trace-demo

# 测试连通性
kubectl run -it --rm debug --image=busybox --restart=Never -- wget -qO- http://<service-ip>:8081/order/health
```

### 配置未生效

```bash
# 检查ConfigMap
kubectl get configmap -n trace-demo

# 查看Pod使用的配置
kubectl get pod -n trace-demo <pod-name> -o yaml | grep -A 10 configMap
```

---

## 📚 参考资源

- [Helm 官方文档](https://helm.sh/docs/)
- [Kubernetes 官方文档](https://kubernetes.io/docs/)
- [Spring Boot on Kubernetes](https://spring.io/guides/topicals/spring-boot-docker/)

---

**祝您部署顺利！🎉**
