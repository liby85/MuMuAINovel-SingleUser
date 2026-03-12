#!/bin/bash
# 单用户化补丁脚本
# 在合并上游代码后自动应用单用户模式修改

set -e  # 遇到错误立即退出

echo "🛠️ 开始应用单用户化补丁..."

# ================================
# 1. 备份文件（如果存在）
# ================================
echo "📋 备份关键文件..."
for file in \
    "backend/app/middleware/auth_middleware.py" \
    "backend/app/database.py" \
    "backend/app/api/auth.py" \
    "backend/app/config.py" \
    "frontend/src/components/ProtectedRoute.tsx" \
    "frontend/src/services/api.ts"; do
    
    if [ -f "$file" ]; then
        cp "$file" "${file}.bak"
    fi
done

# ================================
# 2. 核心文件修改
# ================================

echo "🔧 修改认证中间件..."
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

echo "🔧 修改数据库配置..."
# 保留原始database.py，但添加一些兼容性修改
if [ -f "backend/app/database.py" ]; then
    # 确保 get_single_user_id 函数存在
    grep -q "get_single_user_id" backend/app/database.py || \
    cat >> backend/app/database.py << 'EOF'

# ============ 单用户模式函数 ============
def get_single_user_id() -> str:
    """返回单用户模式下的固定用户ID"""
    return "single_user"
EOF
fi

echo "🔧 修改认证API..."
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

echo "🔧 更新配置文件..."
if [ -f "backend/app/config.py" ]; then
    # 设置单用户模式
    sed -i "s/LOCAL_AUTH_ENABLED = True/LOCAL_AUTH_ENABLED = False/g" backend/app/config.py
    sed -i "s/SESSION_EXPIRE_MINUTES = .*/SESSION_EXPIRE_MINUTES = 999999/g" backend/app/config.py
fi

# ================================
# 3. 前端修改
# ================================

echo "🔧 修改前端保护路由..."
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

echo "🔧 更新前端API客户端..."
# 从api.ts中移除用户相关接口调用
if [ -f "frontend/src/services/api.ts" ]; then
    # 移除 authApi 相关导入和调用
    sed -i '/authApi/d' frontend/src/services/api.ts
    sed -i '/401.*login/d' frontend/src/services/api.ts
fi

# ================================
# 4. Docker 和部署文件
# ================================

echo "🔧 更新Docker启动脚本..."
if [ -f "backend/scripts/entrypoint.sh" ]; then
    # 简化为单用户模式启动脚本
    sed -i '/alembic upgrade/d' backend/scripts/entrypoint.sh
    sed -i '/数据库迁移/d' backend/scripts/entrypoint.sh
    sed -i '/执行数据库迁移/d' backend/scripts/entrypoint.sh
fi

echo "🔧 更新环境变量配置..."
if [ -f ".env.example" ]; then
    # 确保使用 SQLite 配置
    sed -i 's|DATABASE_URL=.*|DATABASE_URL=sqlite+aiosqlite:///data/mumuai.db|g' .env.example
    sed -i 's/LOCAL_AUTH_ENABLED=.*/LOCAL_AUTH_ENABLED=false/g' .env.example
fi

# ================================
# 5. 清理和验证
# ================================

echo "🧹 清理备份文件..."
for file in \
    "backend/app/middleware/auth_middleware.py.bak" \
    "backend/app/database.py.bak" \
    "backend/app/api/auth.py.bak" \
    "backend/app/config.py.bak" \
    "frontend/src/components/ProtectedRoute.tsx.bak" \
    "frontend/src/services/api.ts.bak"; do
    
    if [ -f "$file" ]; then
        rm "$file"
    fi
done

echo "✅ 补丁应用完成！"

# 显示修改摘要
echo ""
echo "📊 修改摘要："
echo "======================================"
echo "1. 认证中间件：替换为单用户版本"
echo "2. 数据库：已配置 SQLite 支持"
echo "3. 认证API：仅保留健康检查"
echo "4. 前端路由：移除登录检查"
echo "5. Docker配置：优化为单容器模式"
echo "======================================"