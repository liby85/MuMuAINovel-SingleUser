"""
认证中间件 - 单用户模式
"""
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from app.logger import get_logger

logger = get_logger(__name__)

class AuthMiddleware(BaseHTTPMiddleware):
    """认证中间件（单用户模式）"""
    
    async def dispatch(self, request: Request, call_next):
        # 始终注入固定的 user_id 和管理员状态
        request.state.is_proxy_request = False
        request.state.proxy_instance_id = None
        request.state.user_id = "single_user"      # 固定用户ID
        request.state.user = None                 # 单用户无需 User 对象
        request.state.is_admin = True             # 默认是管理员
        
        response = await call_next(request)
        return response
