#!/bin/bash

# Helm Chart 验证脚本

set -e

echo "=========================================="
echo "  Helm Chart 验证"
echo "=========================================="
echo ""

CHART_PATH="./helm/trace-order"

# 检查必需文件
echo "检查必需文件..."

required_files=(
    "Chart.yaml"
    "values.yaml"
    "templates/deployment.yaml"
    "templates/service.yaml"
    "templates/_helpers.tpl"
)

all_exist=true
for file in "${required_files[@]}"; do
    if [ -f "$CHART_PATH/$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (缺失)"
        all_exist=false
    fi
done

echo ""

if [ "$all_exist" = true ]; then
    echo "✓ 所有必需文件存在"
else
    echo "✗ 存在缺失文件"
    exit 1
fi

echo ""
echo "验证 Helm Chart 语法..."

# 检查 helm 是否可用
if ! command -v helm &> /dev/null; then
    echo "⚠ helm 未安装，跳过语法检查"
    echo ""
    echo "您可以手动安装 helm: https://helm.sh/docs/intro/install/"
    exit 0
fi

# Lint Chart
echo "执行 helm lint..."
if helm lint $CHART_PATH; then
    echo ""
    echo "✓ Helm Chart 语法验证通过"
else
    echo ""
    echo "✗ Helm Chart 存在语法错误"
    exit 1
fi

echo ""
echo "渲染模板预览..."
helm template test-release $CHART_PATH --debug 2>&1 | head -50

echo ""
echo "=========================================="
echo "  ✓ 验证完成！"
echo "=========================================="
echo ""
echo "下一步操作:"
echo "1. 构建Docker镜像: cd trace-order && docker build -t trace-order:1.0.0 ."
echo "2. 安装应用: ./deploy-order.sh -i -e dev"
echo "3. 查看文档: cat helm/trace-order/README.md"
echo ""
