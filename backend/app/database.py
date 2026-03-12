"""
数据库连接和会话管理 - 单用户模式
"""
import asyncio
from typing import Dict, Any
from datetime import datetime
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from fastapi import Request, HTTPException
from app.config import settings
from app.logger import get_logger

logger = get_logger(__name__)

# 创建基类
Base = declarative_base()

# 导入所有模型，确保 Base.metadata 能够发现它们
from app.models import (
    Project, Outline, Character, Chapter, GenerationHistory,
    Settings, WritingStyle, ProjectDefaultStyle,
    RelationshipType, CharacterRelationship, Organization, OrganizationMember,
    StoryMemory, PlotAnalysis, AnalysisTask, BatchGenerationTask,
    RegenerationTask, Career, CharacterCareer, User, MCPPlugin, PromptTemplate
)

# 引擎缓存：单用户共享引擎
cache_key = "single_shared_engine"
_engine_cache: Dict[str, Any] = {}
_cache_lock = asyncio.Lock()

# 会话统计（用于监控连接泄漏）
_session_stats = {
    "created": 0,
    "closed": 0,
    "active": 0,
    "errors": 0,
    "generator_exits": 0,
    "last_check": None
}


def get_single_user_id() -> str:
    """返回单用户模式下的固定用户ID"""
    return "single_user"

async def get_engine(user_id: str = None):
    """获取或创建共享的数据库引擎（线程安全）"""
    if cache_key in _engine_cache:
        return _engine_cache[cache_key]
    
    async with _cache_lock:
        if cache_key not in _engine_cache:
            # 检测数据库类型
            is_sqlite = 'sqlite' in settings.database_url.lower()
            
            # 基础引擎参数
            engine_args = {
                "echo": settings.database_echo_pool,
                "echo_pool": settings.database_echo_pool,
                "future": True,
            }
            
            if is_sqlite:
                # SQLite 配置
                engine_args["connect_args"] = {
                    "check_same_thread": False,
                    "timeout": 30.0,
                }
                engine_args["pool_pre_ping"] = True
                
                logger.info("📊 使用 SQLite 数据库（NullPool，超时30秒，WAL模式）")
            else:
                # PostgreSQL 配置
                connect_args = {
                    "server_settings": {
                        "application_name": settings.app_name,
                        "jit": "off",
                        "search_path": "public",
                    },
                    "command_timeout": 60,
                    "statement_cache_size": 500,
                }
                
                engine_args.update({
                    "pool_size": settings.database_pool_size,
                    "max_overflow": settings.database_max_overflow,
                    "pool_timeout": settings.database_pool_timeout,
                    "pool_pre_ping": settings.database_pool_pre_ping,
                    "pool_recycle": settings.database_pool_recycle,
                    "pool_use_lifo": settings.database_pool_use_lifo,
                    "pool_reset_on_return": settings.database_pool_reset_on_return,
                    "max_identifier_length": settings.database_max_identifier_length,
                    "connect_args": connect_args
                })
                
                total_connections = settings.database_pool_size + settings.database_max_overflow
                estimated_concurrent_users = total_connections * 2
                
                logger.info(
                    f"📊 PostgreSQL 连接池配置:\n"
                    f"   ├─ 核心连接: {settings.database_pool_size}\n"
                    f"   ├─ 溢出连接: {settings.database_max_overflow}\n"
                    f"   ├─ 总连接数: {total_connections}\n"
                    f"   ├─ 获取超时: {settings.database_pool_timeout}秒\n"
                    f"   ├─ 连接回收: {settings.database_pool_recycle}秒\n"
                    f"   └─ 预估并发: {estimated_concurrent_users}+用户"
                )
            
            engine = create_async_engine(settings.database_url, **engine_args)
            _engine_cache[cache_key] = engine
            
            # 如果是 SQLite，启用 WAL 模式以支持读写并发
            if is_sqlite:
                try:
                    from sqlalchemy import event
                    from sqlalchemy.pool import NullPool
                    
                    @event.listens_for(engine.sync_engine, "connect")
                    def set_sqlite_pragma(dbapi_conn, connection_record):
                        cursor = dbapi_conn.cursor()
                        cursor.execute("PRAGMA journal_mode=WAL")
                        cursor.execute("PRAGMA synchronous=NORMAL")
                        cursor.execute("PRAGMA cache_size=-64000")  # 64MB 缓存
                        cursor.execute("PRAGMA busy_timeout=30000")  # 30秒超时
                        cursor.close()
                    
                    logger.info("✅ SQLite WAL 模式已启用（支持读写并发）")
                except Exception as e:
                    logger.warning(f"⚠️ 启用 WAL 模式失败: {e}，使用默认配置")
        
    return _engine_cache[cache_key]


async def get_db(request: Request = None):
    """获取数据库会话（单用户模式）"""
    # 忽略 request 参数，在单用户模式下始终使用固定 user_id
    engine = await get_engine()
    
    AsyncSessionLocal = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    
    session = AsyncSessionLocal()
    session_id = id(session)
    
    global _session_stats
    _session_stats["created"] += 1
    _session_stats["active"] += 1
    
    try:
        yield session
        if session.in_transaction():
            await session.rollback()
    except GeneratorExit:
        _session_stats["generator_exits"] += 1
        logger.warning(f"⚠️ GeneratorExit [User:single_user][ID:{session_id}] - SSE连接断开（总计:{_session_stats['generator_exits']}次）")
        try:
            if session.in_transaction():
                await session.rollback()
                logger.info(f"✅ 事务已回滚 [User:single_user][ID:{session_id}]（GeneratorExit）")
        except Exception as rollback_error:
            _session_stats["errors"] += 1
            logger.error(f"❌ GeneratorExit回滚失败 [User:single_user][ID:{session_id}]: {str(rollback_error)}")
    except Exception as e:
        _session_stats["errors"] += 1
        logger.error(f"❌ 会话异常 [User:single_user][ID:{session_id}]: {str(e)}")
        try:
            if session.in_transaction():
                await session.rollback()
                logger.info(f"✅ 事务已回滚 [User:single_user][ID:{session_id}]（异常）")
        except Exception as rollback_error:
            logger.error(f"❌ 异常回滚失败 [User:single_user][ID:{session_id}]: {str(rollback_error)}")
        raise
    finally:
        try:
            if session.in_transaction():
                await session.rollback()
                logger.warning(f"⚠️ finally中发现未提交事务 [User:single_user][ID:{session_id}]，已回滚")
            
            await session.close()
            
            _session_stats["closed"] += 1
            _session_stats["active"] -= 1
            _session_stats["last_check"] = datetime.now().isoformat()
            
            if _session_stats["active"] > settings.database_session_leak_threshold:
                logger.error(f"🚨 严重告警：活跃会话数 {_session_stats['active']} 超过泄漏阈值 {settings.database_session_leak_threshold}！")
            elif _session_stats["active"] > settings.database_session_max_active:
                logger.warning(f"⚠️ 警告：活跃会话数 {_session_stats['active']} 超过警告阈值 {settings.database_session_max_active}，可能存在连接泄漏！")
            elif _session_stats["active"] < 0:
                logger.error(f"🚨 活跃会话数异常: {_session_stats['active']}，统计可能不准确！")
                
        except Exception as e:
            _session_stats["errors"] += 1
            logger.error(f"❌ 关闭会话时出错 [User:single_user][ID:{session_id}]: {str(e)}", exc_info=True)
            try:
                await session.close()
            except:
                pass

async def close_db():
    """关闭所有数据库连接"""
    try:
        logger.info("正在关闭所有数据库连接...")
        for key, engine in _engine_cache.items():
            await engine.dispose()
            logger.info(f"{key} 的数据库连接已关闭")
        _engine_cache.clear()
        logger.info("所有数据库连接已关闭")
    except Exception as e:
        logger.error(f"关闭数据库连接失败: {str(e)}", exc_info=True)
        raise
