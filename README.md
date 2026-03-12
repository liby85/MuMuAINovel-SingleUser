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

> 📝 **重要提示**：首次运行前，请在 `.env` 文件中配置你的 **OpenAI API Key**，否则 AI 生成功能将不可用。

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

## 📄 License

MIT License - 与原项目一致

---

> 🚀 由 [@liby85] 基于 AI 协作改造 | 想要多用户版本？请查看 [原项目地址](https://github.com/xiamuceer-j/MuMuAINovel)