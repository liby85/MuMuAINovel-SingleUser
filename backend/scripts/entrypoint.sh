#!/bin/bash
# Docker 容器启动入口脚本（单用户 SQLite 版本）
# 功能：直接启动应用，不再执行数据库迁移

set -e

# 获取版本信息
if [ -z "$APP_VERSION" ]; then
    if [ -f "/app/.env.example" ]; then
        APP_VERSION=$(grep "^APP_VERSION=" /app/.env.example | cut -d '=' -f2)
    fi
    APP_VERSION="${APP_VERSION:-1.0.0}"
fi

if [ -z "$APP_NAME" ]; then
    APP_NAME="${APP_NAME:-MuMuAINovel-SingleUser}"
fi

BUILD_TIME=$(date '+%Y-%m-%d %H:%M:%S')

echo "================================================"
echo "🚀 ${APP_NAME} 启动中..."
echo "📦 版本: v${APP_VERSION}"
echo "🕐 启动时间: ${BUILD_TIME}"
echo "================================================"

# 检查数据库文件
DATABASE_URL="${DATABASE_URL:-sqlite+aiosqlite:///data/mumuai.db}"
DB_FILE=$(echo $DATABASE_URL | sed 's/sqlite+aiosqlite:\/\/\///')

if [ -n "$DB_FILE" ] && [ -f "$DB_FILE" ]; then
    echo "✅ 检测到预初始化数据库: $DB_FILE"
else
    echo "❌ 错误: 未找到数据库文件 $DB_FILE！请确保已正确挂载数据卷。"
    exit 1
fi

# 不再执行数据库迁移
# 因为数据库已包含所有必要结构和预设数据

# 启动应用

echo "================================================"
echo "🎉 启动应用服务..."
echo "================================================"

cd /app
exec uvicorn app.main:app \
    --host "${APP_HOST:-0.0.0.0}" \
    --port "${APP_PORT:-8000}" \
    --log-level info \
    --access-log \
    --use-colors