# Helm 部署快速参考卡

## 📦 一键部署命令

```bash
# 开发环境
./deploy-order.sh -i -e dev

# 生产环境
./deploy-order.sh -i -e prod

# 查看状态
./deploy-order.sh -s

# 升级应用
./deploy-order.sh -u -e prod

# 卸载应用
./deploy-order.sh -d
```

---

## 🔧 手动 Helm 命令

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
```

---

## 📊 常用查询命令

```bash
# 查看 Pod
kubectl get pods -n trace-demo -l app.kubernetes.io/name=trace-order

# 查看日志
kubectl logs -n trace-demo -l app.kubernetes.io/name=trace-order -f

# 端口转发
kubectl port-forward -n trace-demo svc/trace-order 8081:8081

# 健康检查
curl http://localhost:8081/order/health
```

---

## ⚙️ 核心配置项速查

| 配置项 | 说明 | 示例 |
|--------|------|------|
| `replicaCount` | 副本数 | `1`, `3`, `5` |
| `image.repository` | 镜像地址 | `your-registry/trace-order` |
| `image.tag` | 镜像标签 | `1.0.0`, `latest` |
| `service.type` | 服务类型 | `ClusterIP`, `NodePort`, `LoadBalancer` |
| `resources.limits.cpu` | CPU限制 | `500m`, `1000m` |
| `resources.limits.memory` | 内存限制 | `512Mi`, `1024Mi` |
| `env[0].value` | Spring Profile | `dev`, `test`, `prod` |
| `skywalking.enabled` | 启用SkyWalking | `true`, `false` |
| `autoscaling.enabled` | 自动扩缩容 | `true`, `false` |

---

## 🎯 典型场景配置

### 最小化部署 (测试用)

```bash
helm install trace-order ./helm/trace-order -n test \
  --set replicaCount=1 \
  --set resources.limits.cpu=250m \
  --set resources.limits.memory=256Mi
```

### 高可用部署 (生产用)

```bash
helm install trace-order ./helm/trace-order -n prod \
  --set replicaCount=3 \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=3 \
  --set autoscaling.maxReplicas=10 \
  --set podDisruptionBudget.enabled=true \
  --set podDisruptionBudget.minAvailable=2
```

### 启用外部访问

```bash
helm install trace-order ./helm/trace-order -n prod \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=order.example.com \
  --set ingress.className=nginx
```

---

## 🐛 故障排查速查

```bash
# Pod启动失败
kubectl describe pod -n <namespace> <pod-name>

# 查看事件
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# 查看上一个容器的日志
kubectl logs -n <namespace> <pod-name> --previous

# 进入Pod调试
kubectl exec -it -n <namespace> <pod-name> -- /bin/bash

# 检查Service
kubectl get svc,endpoints -n <namespace> -l app.kubernetes.io/name=trace-order
```

---

## 📁 文件位置速查

```
项目根目录/
├── helm/trace-order/           # Helm Chart
│   ├── Chart.yaml             # Chart元数据
│   ├── values.yaml            # 默认配置
│   ├── values-dev.yaml        # 开发环境配置
│   ├── values-prod.yaml       # 生产环境配置
│   ├── README.md              # 详细文档
│   └── templates/             # K8s模板
├── trace-order/
│   ├── Dockerfile             # Docker构建文件
│   └── .dockerignore          # Docker忽略文件
├── deploy-order.sh            # 部署脚本
├── validate-helm.sh           # 验证脚本
└── HELM_DEPLOYMENT_SUMMARY.md # 部署总结
```

---

## 💡 提示与技巧

### 1. 动态覆盖配置

```bash
# 临时调整副本数
helm upgrade trace-order ./helm/trace-order -n trace-demo \
  --set replicaCount=5

# 同时覆盖多个值
helm upgrade trace-order ./helm/trace-order -n trace-demo \
  --set replicaCount=3 \
  --set resources.limits.cpu=1000m \
  --set env[0].value=prod
```

### 2. 使用 --dry-run 预览

```bash
# 预览将创建的资源
helm install trace-order ./helm/trace-order -n trace-demo \
  --dry-run --debug

# 预览渲染后的YAML
helm template trace-order ./helm/trace-order -n trace-demo
```

### 3. 导出当前配置

```bash
# 获取当前生效的配置
helm get values trace-order -n trace-demo

# 获取所有配置（包括默认值）
helm get all trace-order -n trace-demo
```

### 4. 比较配置差异

```bash
# 比较两个版本的配置
helm diff upgrade trace-order ./helm/trace-order \
  -n trace-demo -f values-prod.yaml
```

---

## 🔗 相关链接

- 📖 [完整部署文档](helm/trace-order/README.md)
- 📖 [部署总结](HELM_DEPLOYMENT_SUMMARY.md)
- 🌐 [Helm 官方文档](https://helm.sh/docs/)
- ☸️ [Kubernetes 文档](https://kubernetes.io/docs/)

---

**打印此卡片，随时查阅！📌**
