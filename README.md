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

## 📋 对原项目的修改

本节详细列出从 [xiamuceer-j/MuMuAINovel](https://github.com/xiamuceer-j/MuMuAINovel) 到本单用户版本的所有关键修改。

### 核心架构变更

| 变更项 | 原项目 | 当前版本 | 说明 |
|--------|--------|-----------|-------|
| **部署模式** | 多用户系统 | 单用户系统 | 移除所有认证和用户管理功能 |
| **数据库** | PostgreSQL | SQLite | 改用轻量级文件数据库 |
| **数据隔离** | 多用户 | 单一用户 (`single_user`) | 所有数据归属于固定用户 |
| **容器数量** | 2 (后端 + DB) | 1 (仅后端) | 不再依赖独立数据库容器 |
| **初始化流程** | 需运行 Alembic 迁移 | 开箱即用 | 数据库文件已预初始化 |

### 关键文件修改

#### 后端 (Backend)

| 文件路径 | 修改内容 |
|----------|----------|
| `app/middleware/auth_middleware.py` | 重写为单用户模式，始终注入 `user_id="single_user"`, `is_admin=True` |
| `app/database.py` | 修改 `get_engine()` 以支持 SQLite 并返回单一共享引擎 |
| `app/api/auth.py` | 重写，仅保留 `/auth/health` 健康检查端点 |
| `app/config.py` | 设置 `LOCAL_AUTH_ENABLED = False` |
| `scripts/entrypoint.sh` | 重写，移除对 PostgreSQL 的等待逻辑，禁用迁移 |

#### 前端 (Frontend)

| 文件路径 | 修改内容 |
|----------|----------|
| `src/components/ProtectedRoute.tsx` | 重写，直接渲染子组件，不再检查登录状态 |
| `src/pages/Login.tsx` | 已删除 |
| `src/App.tsx` | 删除 `/login` 和 `/auth/callback` 路由 |
| `src/services/api.ts` | 移除 `authApi` 模块及相关的拦截器 |

#### 配置与构建

| 文件路径 | 修改内容 |
|----------|----------|
| `Dockerfile` | 移除 `postgresql-client` 依赖，简化构建流程 |
| `docker-compose.yml` | 移除 `postgres` 服务，改为使用本地数据卷 |
| `.env.example` | 更新为单用户模式配置，启用 SQLite 连接字符串 |

### 数据库结构

- **数据库文件**: `data/mumuai.db`
- **连接 URL**: `sqlite+aiosqlite:///data/mumuai.db`
- **表结构兼容性**: 完全兼容原项目，未来可无缝升级回多用户模式
- **用户相关表**: `users`, `user_passwords` 等表结构保留但不再使用

---

## 📄 License

MIT License - 与原项目一致

---

> 🚀 由 [@liby85] 基于 AI 协作改造 | 想要多用户版本？请查看 [原项目地址](https://github.com/xiamuceer-j/MuMuAINovel)