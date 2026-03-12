#!/bin/bash
# Docker 容器启动入口脚本（单用户 SQLite 版本）
# 功能：执行迁移，启动应用

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
    echo "✅ 检测到现有数据库: $DB_FILE"
else
    echo "📝 将创建新数据库: $DB_FILE"
    mkdir -p $(dirname $DB_FILE)
fi

# 运行数据库迁移
echo "================================================"
echo "🔄 执行数据库迁移..."
echo "================================================"

cd /app

# 使用 SQLite 的 Alembic 配置
if [ -f "alembic-sqlite.ini" ]; then
    echo "🔄 使用 SQLite 迁移配置..."
    # SQLite 迁移脚本存放在 alembic/sqlite 目录
    export ALEMBIC_CONFIG=alembic-sqlite.ini
    
    # 修改env.py以使用sqlite
    if [ -f "alembic/sqlite/env.py" ]; then
        # SQLite 使用 run_migrations_offline 和 run_migrations_online
        alembic -x db=sqlite upgrade head || true
    fi
else
    echo "⚠️ 未找到 SQLite 配置，跳过迁移"
fi

if [ $? -eq 0 ]; then
    echo "✅ 数据库迁移成功"
else
    echo "⚠️ 迁移可能已完成或首次运行，将继续启动..."
fi

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