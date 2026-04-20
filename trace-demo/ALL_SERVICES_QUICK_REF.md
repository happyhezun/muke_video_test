# 全服务 Helm 部署速查表

## 🚀 一键命令

```bash
# 安装所有服务
./deploy-all.sh -i -s all -e dev      # 开发环境
./deploy-all.sh -i -s all -e prod     # 生产环境

# 查看状态
./deploy-all.sh -st -s all

# 卸载所有服务
./deploy-all.sh -d -s all
```

---

## 📦 服务清单

| 服务 | Chart路径 | 端口 | 健康检查 | 依赖 |
|------|----------|------|---------|------|
| **Order** | `helm/trace-order/` | 8081 | `/order/health` | Inventory |
| **Inventory** | `helm/trace-inventory/` | 8082 | `/inventory/health` | 无 |
| **Gateway** | `helm/trace-gateway/` | 8080 | `/health` | Order + Inventory |

---

## 🔧 单服务操作

```bash
# 订单服务
./deploy-all.sh -i -s order -e dev
./deploy-all.sh -u -s order -e prod
./deploy-all.sh -d -s order

# 库存服务
./deploy-all.sh -i -s inventory -e dev

# 网关服务
./deploy-all.sh -i -s gateway -e prod
```

---

## 📊 验证命令

```bash
# 查看所有Pod
kubectl get pods -n trace-demo

# 查看所有Service
kubectl get svc -n trace-demo

# 端口转发网关
kubectl port-forward -n trace-demo svc/trace-gateway 8080:8080

# 测试访问
curl http://localhost:8080/health
curl http://localhost:8080/order/health
curl http://localhost:8080/inventory/health
```

---

## 🎯 典型场景

### 完整部署流程

```bash
# 1. 构建镜像
cd trace-order && docker build -t your-registry/trace-order:1.0.0 . && cd ..
cd trace-inventory && docker build -t your-registry/trace-inventory:1.0.0 . && cd ..
cd trace-gateway && docker build -t your-registry/trace-gateway:1.0.0 . && cd ..

# 2. 推送镜像
docker push your-registry/trace-order:1.0.0
docker push your-registry/trace-inventory:1.0.0
docker push your-registry/trace-gateway:1.0.0

# 3. 部署到K8s
./deploy-all.sh -i -s all -e dev

# 4. 验证
./deploy-all.sh -st -s all
```

### 生产环境升级

```bash
# 更新values-prod.yaml中的镜像版本
# 然后执行升级
./deploy-all.sh -u -s all -e prod

# 回滚（如果出问题）
helm rollback trace-order 1 -n trace-demo
helm rollback trace-inventory 1 -n trace-demo
helm rollback trace-gateway 1 -n trace-demo
```

---

## 🐛 故障排查

```bash
# Pod启动失败
kubectl describe pod -n trace-demo <pod-name>

# 查看日志
kubectl logs -n trace-demo -l app.kubernetes.io/name=trace-order -f

# 检查事件
kubectl get events -n trace-demo --sort-by='.lastTimestamp'

# 测试服务连通性
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  wget -qO- http://trace-order:8081/order/health
```

---

## 📁 文件位置

```
项目根目录/
├── helm/
│   ├── trace-order/           # 订单服务Chart
│   ├── trace-inventory/       # 库存服务Chart
│   └── trace-gateway/         # 网关服务Chart
├── deploy-all.sh              # 统一部署脚本 ⭐
├── HELM_CHARTS_GUIDE.md       # 完整指南 ⭐
└── ALL_CHARTS_COMPLETED.md    # 完成总结
```

---

## 💡 提示

### 部署顺序
脚本自动按依赖顺序部署：
1. Inventory (无依赖)
2. Order (依赖Inventory)
3. Gateway (依赖Order+Inventory)

### 环境差异
- **Dev**: 单副本，DEBUG日志，ClusterIP
- **Prod**: 多副本+HPA，WARN日志，Gateway用LoadBalancer

### 资源建议
- Dev: CPU 500m, Memory 512Mi
- Prod: CPU 1000m, Memory 1024Mi

---

**打印此卡片，随时查阅！📌**
