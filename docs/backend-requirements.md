# 次元链接 后端需求文档

| 项 | 内容 |
| --- | --- |
| 产品 | 次元链接（Dimension Link） |
| 客户端 | Flutter App `dimension_link` 1.0.0+1 |
| 包名 | `com.mingcoldmoon.dimension_link` |
| 对照代码 | `lib/models/models.dart`、`lib/state/app_state.dart`、`lib/data/mock_seed.dart` |
| 文档版本 | 1.0 |
| 日期 | 2026-09-08 |

配套接口契约见 [backend-api.md](./backend-api.md)。

---

## 1. 背景与目标

当前 App 全部社交数据在本地 mock，登录会话只把 `user_id` 写入 `SharedPreferences`。后端第一期目标是：**用服务端替换 mock，让现有页面不改交互也能跑通真实账号、动态、圈子、私信和个人主页。**

成功标准：

1. 现有 5 个 Tab / 页面流（启动 → 登录/注册 → 广场 / 圈子 / 消息 / 我的 / 搜索）都能打到后端。
2. `AppState` 中每一类写操作都有对应接口（见第 6 节对照表）。
3. 种子住民、圈子、动态可导入，便于联调（演示账号 `星野铃` 仍可登录）。

## 2. 范围

### 2.1 本期必做（P0，对齐现客户端）

- 注册、登录、登出、会话恢复
- 当前用户资料查询与编辑（昵称、简介、签名）
- 住民主页、关注 / 取关
- 广场动态流、按用户、按圈子拉取
- 发布动态（正文、圈子、心情签、配图标题）
- 点赞、星标、评论
- 圈子列表、加入 / 退出、圈子详情动态
- 私信会话列表、确保会话、发消息、已读
- 系统通知列表
- 搜索住民、动态、圈子

配图在客户端用 `imageHue` + `imageTitle` 画插画卡，**本期不强制真实图片存储**，但字段必须持久化，便于以后换成 URL。

### 2.2 本期明确不做（P1+）

| 项 | 说明 |
| --- | --- |
| 真实图片 / 视频上传 | 客户端尚无相册选择 |
| WebSocket 长连接 | 私信与通知先用 HTTP 拉取 |
| 手机号 / 第三方登录 | 现登录为昵称或 `@handle` + 口令 |
| 动态删除、评论删除 | 客户端无入口 |
| 拉黑、举报、审核后台 | 上线前再补 |
| 推送（Push） | 无设备 token 流程 |
| 支付、会员 | 无 |

P1 建议在接口上预留分页、`avatarUrl`、`imageUrl`，避免下次大改契约。

## 3. 角色

| 角色 | 说明 |
| --- | --- |
| 游客 | 仅启动页、登录、注册 |
| 住民（登录用户） | 全部社交能力 |
| 运营（人工） | 本期无后台；圈子先用种子数据，不开放用户自建圈子 |

## 4. 客户端页面与能力

| 页面 | 文件 | 需要后端 |
| --- | --- | --- |
| 启动 | `splash_screen.dart` | 用本地 token 调「当前用户」；失败则去登录 |
| 登录 | `login_screen.dart` | 标识（昵称或 handle）+ 口令 |
| 注册 | `register_screen.dart` | nickname、handle、password |
| 广场 | `feed_screen.dart` | 动态列表（时间倒序）+ 当前用户摘要 |
| 发布 | `compose_screen.dart` | 创建动态 |
| 动态详情 | `post_detail_screen.dart` | 动态详情 + 评论列表 + 发评论 |
| 圈子 | `community_screen.dart` | 圈子列表 + 是否已加入 |
| 圈子详情 | `circle_detail_screen.dart` | 圈子信息 + 该圈子动态 + 加入/退出 |
| 消息 | `messages_screen.dart` | 通知列表 + 会话列表（未读数、最后一条） |
| 聊天 | `chat_screen.dart` | 历史消息 + 发送 |
| 我的 | `profile_screen.dart` | 自己的资料、徽章、自己的动态、登出 |
| 编辑资料 | `edit_profile_screen.dart` | 更新 nickname / bio / signature |
| 他人主页 | `user_profile_screen.dart` | 资料、是否已关注、关注、发起私信、其动态 |
| 搜索 | `search_screen.dart` | 同时搜用户、圈子、动态 |

底部导航未读数 = 所有会话 `unread` 之和。

## 5. 领域对象

与 `lib/models/models.dart` 对齐。密码只存在服务端，**禁止**下发给客户端。

### 5.1 住民 User

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | string | 主键，如 `u_me` |
| nickname | string | 展示名，登录可用 |
| handle | string | 形如 `@hoshi_suzu`，全局唯一（大小写不敏感） |
| bio | string | 简介 |
| signature | string | 签名 |
| emoji | string | 头像占位表情 |
| accentIndex | int | 0–7，对应客户端配色盘 |
| followers | int | 粉丝数 |
| following | int | 关注数 |
| level | int | 等级 |
| badges | string[] | 徽章文案 |
| passwordHash | string | 仅服务端 |
| createdAt | datetime | 注册时间 |

注册默认：`bio=刚刚穿越过来的新住民`，`signature=请多指教～`，`emoji=✨`，`level=1`，`badges=["初入次元"]`，`followers=0`，`following=0`，`accentIndex` 按用户数取模 8。

### 5.2 心情签 MoodTag

与客户端枚举一致，接口传 **英文 key**：

| key | 文案 | 符号 |
| --- | --- | --- |
| happy | 开心 | ✿ |
| excited | 高能 | ✦ |
| sleepy | 摸鱼 | ☾ |
| love | 心动 | ♡ |
| sad | 破防 | ☁ |
| fire | 安利 | ★ |

### 5.3 动态 Post

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | string | |
| authorId | string | |
| content | string | 正文，去首尾空白后非空 |
| createdAt | datetime | |
| mood | MoodTag key | |
| circleId | string | 必须是已有圈子 |
| imageHue | int | 0–359，客户端画渐变用 |
| imageTitle | string | 空则服务端填 `今日速记` |
| likeCount / liked | int / bool | 对当前用户是否已赞 |
| starCount / starred | int / bool | 是否已星标 |
| commentCount | int | |

列表接口不要把全部 `likedBy` 用户 id 数组吐给客户端，只给计数 + 当前用户布尔值。

### 5.4 评论 Comment

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | string | |
| postId | string | |
| userId | string | |
| content | string | 去空白后非空 |
| createdAt | datetime | |

### 5.5 圈子 Circle

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | string | 种子 id 固定，见下表 |
| name | string | |
| emoji | string | |
| desc | string | |
| memberCount | int | |
| accentIndex | int | 0–7 |
| tags | string[] | |
| joined | bool | 当前用户是否加入 |

种子圈子（id 不可变，客户端 mock 已写死）：

| id | name |
| --- | --- |
| c_doujin | 同人创作 |
| c_cos | COSPLAY |
| c_anime | 番剧安利 |
| c_art | 绘圈日常 |
| c_game | 游戏开黑 |
| c_voice | 声优电台 |

### 5.6 会话 Conversation 与消息 ChatMessage

一对一会话。参与者为当前用户与 `peerId`。同一对用户只允许一条会话。

| 会话字段 | 说明 |
| --- | --- |
| id | |
| peerId | 对方用户 id |
| unread | 当前用户未读条数 |
| lastMessage | 可空 |

| 消息字段 | 说明 |
| --- | --- |
| id | |
| conversationId | |
| senderId | |
| text | 去空白后非空 |
| createdAt | |

### 5.7 通知 Notice

| 字段 | 说明 |
| --- | --- |
| id | |
| title | |
| body | |
| createdAt | |
| kind | `badge` / `star` / `circle` / `like` / `follow` / `comment` |

星标他人动态、被关注等写操作应插入通知（P0 至少：star、follow；like/comment 建议一起做）。

## 6. 业务规则

### 6.1 认证

- 登录标识：去掉前导 `@` 后，与 `handle`（不含或含 `@`）或 `nickname` 匹配，**大小写不敏感**。
- 口令错误文案：`通行证口令不对哦`
- 用户不存在文案：`找不到这位次元住民`
- 注册：昵称去空白后长度 ≥ 2，否则 `昵称再可爱一点点`
- 注册：口令长度 ≥ 4，否则 `口令至少 4 位`
- 注册：handle 去 `@` 后全局唯一（大小写不敏感），冲突 `这个 @ 已经被占用啦`
- handle 为空时服务端生成 `user_{n}` 类唯一 handle（与现客户端一致）
- 登出使 refresh token 失效（若采用双 token）
- 不能关注自己
- 未登录写操作一律 401

### 6.2 动态与互动

- 广场默认按 `createdAt` **倒序**
- 点赞 / 星标为 **toggle**：已赞再调则取消
- 评论追加在列表末尾（详情页按时间正序展示即可）
- 发布必须指定存在的 `circleId`
- 正文为空拒绝

### 6.3 圈子

- 加入 / 退出为 toggle
- `memberCount` 随加入退出增减，不低于 0
- 新用户默认加入种子前 3 个圈子（`c_doujin`、`c_cos`、`c_anime`），与 `AppState` 构造逻辑一致

### 6.4 私信

- 从他人主页「发私信」：若会话不存在则创建空会话
- 发送成功后，对发送方该会话 `unread=0`；接收方 `unread+1`
- 「标记已读」把当前用户该会话未读清零
- 会话列表按最后消息时间倒序（无消息的新建会话排前面或按创建时间，客户端目前把新建插到列表头）

### 6.5 关注

- toggle；更新双方 `followers` / `following`
- 建议给被关注者写一条 `kind=follow` 通知

### 6.6 搜索

- query 去空白；空 query 可返回推荐/全量截断列表（客户端空搜会列出用户和圈子、全部动态）
- 动态：匹配正文、作者昵称、圈子名
- 用户：匹配 nickname、handle、bio
- 圈子：匹配 name、desc

## 7. 客户端写操作对照（验收用）

| AppState 方法 | 后端能力 |
| --- | --- |
| `restoreSession` | GET `/v1/me` + 本地 token |
| `login` | POST `/v1/auth/login` |
| `register` | POST `/v1/auth/register` |
| `logout` | POST `/v1/auth/logout` |
| `toggleLike` | POST `/v1/posts/{id}/like` |
| `toggleStar` | POST `/v1/posts/{id}/star` |
| `addComment` | POST `/v1/posts/{id}/comments` |
| `composePost` | POST `/v1/posts` |
| `toggleFollow` | POST `/v1/users/{id}/follow` |
| `toggleJoinCircle` | POST `/v1/circles/{id}/join` |
| `sendMessage` | POST `/v1/conversations/{id}/messages` |
| `markConversationRead` | POST `/v1/conversations/{id}/read` |
| `updateProfile` | PATCH `/v1/me` |
| `ensureConversation` | POST `/v1/conversations` |
| `searchPosts` / `searchUsers` | GET `/v1/search` |
| `posts` / `postsOfUser` / `postsOfCircle` | GET 动态列表（query 过滤） |
| `notices` | GET `/v1/notices` |
| `conversations` | GET `/v1/conversations` |

## 8. 联调种子数据

至少导入 `mock_seed.dart` 中的 6 个用户、6 个圈子、6 条动态、3 个会话、3 条通知。演示账号：

- 昵称 `星野铃`，handle `@hoshi_suzu`，口令 `123456`，id 建议保持 `u_me` 以免文档和旧数据对不上。

其余用户默认口令同样 `123456`（仅开发/预发环境）。

## 9. 非功能

| 项 | 要求 |
| --- | --- |
| 协议 | HTTPS，JSON，UTF-8 |
| 时间 | UTC，ISO-8601 |
| 分页 | 列表接口必须支持 cursor 或 page；客户端第一期可只吃第一页 |
| 限流 | 登录/注册按 IP；发帖/私信按用户 |
| 口令 | 哈希存储（如 Argon2id / bcrypt），明文禁止落库 |
| 日志 | 不记录口令、token 全文 |
| 时钟 | 列表排序以服务端时间为准 |

## 10. 验收清单

- [ ] 用错误口令登录，返回「通行证口令不对哦」
- [ ] 用未知昵称登录，返回「找不到这位次元住民」
- [ ] 注册重复 handle，返回「这个 @ 已经被占用啦」
- [ ] 登录后拉广场，动态按时间倒序且含作者、圈子、心情、赞/星/评计数
- [ ] 发布动态后出现在广场与「我的」
- [ ] 点赞、星标再点一次会取消
- [ ] 评论出现在详情页
- [ ] 加入/退出圈子，`joined` 与 `memberCount` 正确
- [ ] 关注他人后双方计数变化，可发私信
- [ ] 发消息后对方会话未读增加；已读清零
- [ ] 搜索「开黑」能命中对应动态；搜索「桜井」能命中用户
- [ ] token 失效后写接口 401，客户端可退回登录
