## MuMuAINovel-SingleUser

> **单用户版 MuMuAINovel** | 无登录 · 开箱即用

本项目是 [xiamuceer-j/MuMuAINovel](https://github.com/xiamuceer-j/MuMuAINovel) 的**单用户简化版本**，专为个人本地部署设计。移除了所有登录、认证和用户管理功能，启动即用，适合私人写作与创作。

---

## ✨ 特性

- ✅ **无需登录**：打开即进入主界面，告别账号系统
- ✅ **数据独立**：所有内容归属于单一用户 `single_user`
- ✅ **结构兼容**：保留原始数据库结构，未来可轻松扩展回多用户模式
- ✅ **完整功能**：大纲、角色、章节、伏笔、灵感工坊等核心功能全部保留
- ✅ **Docker 一键部署**：支持 `docker-compose up` 直接运行

## 📦 部署方式

```bash
# 克隆仓库（待创建）
git clone https://github.com/liby85/MuMuAINovel-SingleUser.git

cd MuMuAINovel-SingleUser

# 启动服务
docker-compose up
```

访问：`http://localhost:3000`

## 🛠️ 技术说明

- **后端**：FastAPI + PostgreSQL + Alembic
- **前端**：React + Vite
- **认证层**：中间件自动注入 `user_id = "single_user"` 和 `is_admin = true`
- **数据库**：保留 `users` 表结构但不再使用

## 🔄 与原项目的差异

| 功能 | 原项目 | 单用户版 |
|------|--------|---------|
| 登录页面 | 有 | 已移除 |
| OAuth 支持 | 有 | 已移除 |
| 用户管理后台 | 有 | 已移除 |
| 多用户隔离 | 是 | 否 |
| Cookie 认证 | 是 | 绕过 |
| 数据模型兼容性 | — | ✅ 完全兼容 |

## 📄 License

MIT License - 与原项目一致

---

> 🚀 由 [@liby85] 基于 AI 协作改造 | 想要多用户版本？请查看 [原项目地址](https://github.com/xiamuceer-j/MuMuAINovel)
