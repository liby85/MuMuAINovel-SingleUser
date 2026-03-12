#!/bin/bash
# 单用户化补丁脚本
# 在合并上游代码后自动应用单用户模式修改

set -e  # 遇到错误立即退出

echo "🛠️ 开始应用单用户化补丁..."

# ================================
# 1. 关键文件检查
# ================================
echo "📋 检查关键文件..."
for file in \
    "backend/app/middleware/auth_middleware.py" \
    "backend/app/database.py" \
    "backend/app/api/auth.py" \
    "backend/app/config.py" \
    "frontend/src/components/ProtectedRoute.tsx" \
    "frontend/src/App.tsx" \
    "frontend/src/services/api.ts" \
    "backend/scripts/entrypoint.sh" \
    ".env.example" \
    "docker-compose.yml" \
    "Dockerfile"; do
    
    if [ ! -f "$file" ]; then
        echo "⚠️  警告: 文件 $file 不存在，可能上游有结构变动"
    else
        echo "✅  $file 存在"
    fi
done

# ================================
# 2. 核心文件修改（使用现有版本的文件）
# ================================

echo ""
echo "🔧 开始应用具体修改..."

# 2.1 认证中间件 - 使用我们精心编写的单用户版本
echo "1. 替换认证中间件..."
if [ -f "backend/app/middleware/auth_middleware.py" ]; then
    cp "backend/app/middleware/auth_middleware.py" "backend/app/middleware/auth_middleware.py.upstream"
    
    # 完全替换为我们经过验证的单用户版本
    cat > backend/app/middleware/auth_middleware.py << 'EOF'
"""
认证中间件 - 单用户模式
简化版本，始终注入单用户身份
"""

from fastapi import Request
from app.logger import get_logger

logger = get_logger(__name__)

async def auth_middleware(request: Request, call_next):
    """
    单用户模式中间件
    始终注入 user_id="single_user" 和 is_admin=True
    """
    # 注入固定用户信息
    request.state.user_id = "single_user"
    request.state.is_admin = True
    
    logger.debug(f"单用户模式: user_id={request.state.user_id}, is_admin={request.state.is_admin}")
    
    # 继续处理请求
    response = await call_next(request)
    return response
EOF
fi

# 2.2 数据库配置 - 确保有 get_single_user_id() 函数
echo "2. 完善数据库配置..."
if [ -f "backend/app/database.py" ]; then
    # 备份原始文件
    cp "backend/app/database.py" "backend/app/database.py.upstream"
    
    # 检查是否已有 get_single_user_id 函数
    if ! grep -q "def get_single_user_id" backend/app/database.py; then
        echo "# 添加 get_single_user_id 函数"
        # 在文件末尾添加
        cat >> backend/app/database.py << 'EOF'

# ============ 单用户模式函数 ============
def get_single_user_id() -> str:
    """返回单用户模式下的固定用户ID"""
    return "single_user"
EOF
    fi
    
    # 确保 SQLite 支持（如果使用 PostgreSQL 配置）
    sed -i "s|'postgresql' in|'sqlite' in|g" backend/app/database.py 2>/dev/null || true
fi

# 2.3 认证API - 完全简化
echo "3. 简化认证API..."
if [ -f "backend/app/api/auth.py" ]; then
    cp "backend/app/api/auth.py" "backend/app/api/auth.py.upstream"
    
    cat > backend/app/api/auth.py << 'EOF'
"""
认证API - 单用户模式简化版
仅保留健康检查端点
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.logger import get_logger

logger = get_logger(__name__)

router = APIRouter(tags=["认证"])

@router.get("/health")
async def health_check(db: AsyncSession = Depends(get_db)):
    """健康检查端点"""
    return {"status": "healthy", "message": "单用户模式运行中"}

# 单用户模式下不再需要其他认证端点
EOF
fi

# 2.4 配置文件 - 设置为单用户模式
echo "4. 更新应用配置..."
if [ -f "backend/app/config.py" ]; then
    cp "backend/app/config.py" "backend/app/config.py.upstream"
    
    # 设置单用户模式标志
    sed -i "s/LOCAL_AUTH_ENABLED = True/LOCAL_AUTH_ENABLED = False/g" backend/app/config.py
    sed -i "s/LOCAL_AUTH_ENABLED = true/LOCAL_AUTH_ENABLED = False/g" backend/app/config.py
    sed -i "s/LOCAL_AUTH_ENABLED=True/LOCAL_AUTH_ENABLED = False/g" backend/app/config.py
    
    # 设置超长会话时间（虽然不会真正使用）
    sed -i "s/SESSION_EXPIRE_MINUTES = [0-9]*/SESSION_EXPIRE_MINUTES = 999999/g" backend/app/config.py
fi

# ================================
# 3. 前端修改
# ================================

# 3.1 保护路由 - 简化为直接渲染
echo "5. 简化前端保护路由..."
if [ -f "frontend/src/components/ProtectedRoute.tsx" ]; then
    cp "frontend/src/components/ProtectedRoute.tsx" "frontend/src/components/ProtectedRoute.tsx.upstream"
    
    cat > frontend/src/components/ProtectedRoute.tsx << 'EOF'
import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';

/**
 * 单用户模式下的保护路由组件
 * 不再检查登录状态，直接渲染子组件
 */
const ProtectedRoute: React.FC = () => {
  // 单用户模式：始终允许访问
  return <Outlet />;
};

export default ProtectedRoute;
EOF
fi

# 3.2 前端路由 - 移除登录相关路由
echo "6. 清理前端路由..."
if [ -f "frontend/src/App.tsx" ]; then
    cp "frontend/src/App.tsx" "frontend/src/App.tsx.upstream"
    
    # 移除登录相关的导入和路由
    sed -i "/import.*Login/d" frontend/src/App.tsx
    sed -i "/import.*AuthCallback/d" frontend/src/App.tsx
    sed -i "/\/login/d" frontend/src/App.tsx
    sed -i "/\/auth\/callback/d" frontend/src/App.tsx
fi

# 3.3 API 客户端 - 移除用户认证相关
echo "7. 清理API客户端..."
if [ -f "frontend/src/services/api.ts" ]; then
    cp "frontend/src/services/api.ts" "frontend/src/services/api.ts.upstream"
    
    # 移除 authApi 相关导入
    sed -i "/authApi/d" frontend/src/services/api.ts
    
    # 移除拦截器中关于登录跳转的逻辑
    sed -i "/401.*login/d" frontend/src/services/api.ts
    sed -i "/window.location.href.*login/d" frontend/src/services/api.ts
    sed -i "/redirect.*login/d" frontend/src/services/api.ts
fi

# ================================
# 4. Docker 和部署配置
# ================================

# 4.1 Docker 启动脚本 - 禁用数据库迁移
echo "8. 优化Docker启动脚本..."
if [ -f "backend/scripts/entrypoint.sh" ]; then
    cp "backend/scripts/entrypoint.sh" "backend/scripts/entrypoint.sh.upstream"
    
    # 移除等待 PostgreSQL 和数据库迁移的逻辑
    sed -i '/等待数据库就绪/,/echo "✅ 数据库已就绪"/d' backend/scripts/entrypoint.sh
    sed -i '/执行数据库迁移/,/echo "✅ 数据库迁移成功"/d' backend/scripts/entrypoint.sh
    sed -i '/alembic upgrade/d' backend/scripts/entrypoint.sh
    
    # 简化启动逻辑
    cat > backend/scripts/entrypoint.sh << 'EOF'
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
EOF
fi

# 4.2 环境变量配置
echo "9. 更新环境变量配置..."
if [ -f ".env.example" ]; then
    cp ".env.example" ".env.example.upstream"
    
    # 确保使用 SQLite
    sed -i 's|DATABASE_URL=.*|DATABASE_URL=sqlite+aiosqlite:///data/mumuai.db|g' .env.example 2>/dev/null || true
    
    # 禁用认证
    sed -i 's|LOCAL_AUTH_ENABLED=.*|LOCAL_AUTH_ENABLED=false|g' .env.example 2>/dev/null || true
    
    # 移除 PostgreSQL 相关配置
    sed -i '/POSTGRES_/d' .env.example 2>/dev/null || true
fi

# 4.3 Docker Compose - 移除 PostgreSQL 服务
echo "10. 更新Docker Compose配置..."
if [ -f "docker-compose.yml" ]; then
    cp "docker-compose.yml" "docker-compose.yml.upstream"
    
    # 移除 postgres 服务相关部分
    sed -i '/postgres:/,/^  mumuainovel:/{/^  mumuainovel:/!d}' docker-compose.yml 2>/dev/null || true
    
    # 确保环境变量正确
    sed -i 's|DATABASE_URL=.*|DATABASE_URL=sqlite+aiosqlite:///data/mumuai.db|g' docker-compose.yml 2>/dev/null || true
    sed -i 's|LOCAL_AUTH_ENABLED=.*|LOCAL_AUTH_ENABLED=false|g' docker-compose.yml 2>/dev/null || true
fi

# 4.4 Dockerfile - 移除不必要依赖
echo "11. 优化Dockerfile..."
if [ -f "Dockerfile" ]; then
    cp "Dockerfile" "Dockerfile.upstream"
    
    # 移除 postgresql-client
    sed -i '/postgresql-client/d' Dockerfile 2>/dev/null || true
    
    # 确保复制 migrate.py 脚本
    if ! grep -q "COPY.*migrate.py" Dockerfile; then
        sed -i '/COPY backend\/scripts\/entrypoint.sh/a COPY backend/scripts/migrate.py /app/scripts/migrate.py' Dockerfile 2>/dev/null || true
    fi
fi

# ================================
# 5. 清理和验证
# ================================

echo ""
echo "🧹 清理临时文件..."
# 删除上游备份文件
find . -name "*.upstream" -delete 2>/dev/null || true

echo "✅ 补丁应用完成！"

# 显示修改摘要
echo ""
echo "📊 修改摘要："
echo "======================================"
echo "✅ 认证中间件：替换为单用户版本"
echo "✅ 数据库：已配置 SQLite 支持"
echo "✅ 认证API：仅保留健康检查"
echo "✅ 前端路由：移除登录检查"
echo "✅ Docker配置：优化为单容器模式"
echo "======================================"
echo ""
echo "🚀 准备就绪！可以提交和构建了。"