# MuMuAINovel-SingleUser

> **单用户版 MuMuAINovel** | 无登录 · SQLite 轻量部署

本项目是 [xiamuceer-j/MuMuAINovel](https://github.com/xiamuceer-j/MuMuAINovel) 的**单用户简化版本**，专为个人本地部署设计。

---

## ✨ 特性

- ✅ **无需登录**：打开即进入主界面，告别账号系统
- ✅ **SQLite 轻量数据库**：无需额外安装 PostgreSQL，一个文件搞定
- ✅ **一键启动**：Docker Compose 单命令部署
- ✅ **数据便携**：数据库文件可直接备份、迁移
- ✅ **完整功能**：大纲、角色、章节、伏笔、灵感工坊等核心功能全部保留

## 📦 部署方式

```bash
# 克隆仓库
git clone https://github.com/liby85/MuMuAINovel-SingleUser.git

cd MuMuAINovel-SingleUser

# 复制配置文件
cp .env.example .env

# 编辑 .env 文件（必须设置 OpenAI API Key）
# vim .env  # 或使用 nano .env

# 启动服务
docker-compose up -d
```

访问：`http://localhost:8000`

> ✅ **无需初始化**：数据库已预置，启动即用！

---

## 🗂️ 数据位置

| 内容 | 路径 |
|------|------|
| 数据库文件 | `./data/mumuai.db` |
| 日志文件 | `./logs/app.log` |

- 数据库文件可随时备份：`cp -r data data.backup`
- 迁移数据：直接复制 `mumuai.db` 文件到新机器

---

## 🛠️ 技术说明

- **后端**：FastAPI + SQLite (aiosqlite)
- **前端**：React + Vite
- **认证层**：中间件自动注入 `user_id = "single_user"` 和 `is_admin = true`
- **数据库**：使用 SQLite WAL 模式，支持读写并发

---

## 🔄 与原项目的差异

| 功能 | 原项目 | 单用户版 |
|------|--------|---------|
| 数据库 | PostgreSQL | SQLite（轻量） |
| 登录页面 | 有 | 已移除 |
| OAuth 支持 | 有 | 已移除 |
| 用户管理后台 | 有 | 已移除 |
| Docker 服务 | 2个容器 | 1个容器 |
| 数据迁移 | 需导入导出 | 直接复制文件 |

---

## 🆚 为什么选择 SQLite？

1. **零配置**：无需安装数据库服务
2. **单文件**：整个数据库只是一个 `.db` 文件
3. **高性能**：对于单用户场景，SQLite 性能足够
4. **易备份**：一行命令完成备份：`cp data/mumuai.db backup/`
5. **易迁移**：复制文件即可迁移到新服务器

---

## 📋 完整变更清单

本节记录了从原项目到单用户版本的所有文件变更。

### 后端 (Backend)

| 文件路径 | 修改类型 | 说明 |
|----------|----------|------|
| `backend/app/middleware/auth_middleware.py` | 重写 | 移除 Cookie 认证逻辑，始终注入 `user_id="single_user"` 和 `is_admin=True` |
| `backend/app/database.py` | 修改 | `get_engine()` 使用单一共享引擎，添加 `get_single_user_id()` 函数，自动检测 SQLite/PostgreSQL |
| `backend/app/api/auth.py` | 重写 | 移除所有登录、登出、密码接口，仅保留健康检查端点 `/auth/health` |
| `backend/app/config.py` | 修改 | `LOCAL_AUTH_ENABLED = False`，会话过期时间设为超长周期 |
| `backend/.env.example` | 修改 | 注释 OAuth 配置，`LOCAL_AUTH_ENABLED=false`，添加 SQLite 配置示例 |
| `backend/scripts/entrypoint.sh` | 重写 | 简化为无需等待外部数据库，启动时自动迁移 SQLite |

### 前端 (Frontend)

| 文件路径 | 修改类型 | 说明 |
|----------|----------|------|
| `frontend/src/components/ProtectedRoute.tsx` | 重写 | 移除登录检查逻辑，直接渲染子组件 |
| `frontend/src/pages/Login.tsx` | 删除 | 登录页面已移除 |
| `frontend/src/App.tsx` | 修改 | 删除 `/login` 和 `/auth/callback` 路由，移除 Login 组件导入 |
| `frontend/src/services/api.ts` | 修改 | 移除 `authApi` 模块，移除 401 跳转拦截器 |

### 配置文件

| 文件路径 | 修改类型 | 说明 |
|----------|----------|------|
| `docker-compose.yml` | 重构 | 移除 PostgreSQL 服务，改用 SQLite + 数据卷挂载 |
| `.env.example` | 新建 | 单用户版配置文件模板 |
| `README.md` | 替换 | 完整的单用户版使用说明 |

### 数据库

| 操作 | 说明 |
|------|------|
| 数据库类型 | PostgreSQL → SQLite |
| 连接方式 | `sqlite+aiosqlite:///data/mumuai.db` |
| 数据模型 | 保留 `users` 表结构但不使用，确保可逆扩展 |

---

## 📄 License

MIT License - 与原项目一致

---

> 🚀 由 [@liby85] 基于 AI 协作改造 | 想要多用户版本？请查看 [原项目地址](https://github.com/xiamuceer-j/MuMuAINovel)