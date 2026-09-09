# 次元链接 API 对接文档

| 项 | 内容 |
| --- | --- |
| Base URL | `https://{host}/v1`（本地可 `http://127.0.0.1:8080/v1`） |
| 格式 | `Content-Type: application/json` |
| 鉴权 | `Authorization: Bearer {accessToken}` |
| 时间 | ISO-8601，UTC，例如 `2026-09-08T12:00:00Z` |
| 需求 | [backend-requirements.md](./backend-requirements.md) |
| 版本 | 1.0 |

本文定义 Flutter 客户端替换 `AppState` mock 时应调用的 HTTP 契约。字段命名使用 camelCase，与 Dart 模型一致。

---

## 1. 统一响应

成功：

```json
{
  "code": 0,
  "message": "ok",
  "data": {}
}
```

失败：HTTP 状态码仍按语义使用（400/401/404/409/422/429/500），body 同样包一层：

```json
{
  "code": 1002,
  "message": "通行证口令不对哦",
  "data": null
}
```

客户端优先展示 `message`（需为中文，与现 UI 一致）。

列表：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "items": [],
    "nextCursor": null,
    "hasMore": false
  }
}
```

- `limit` 默认 20，最大 50。
- `cursor` 为上一页返回的 `nextCursor`；首页不传。
- 第一期客户端可以忽略 `nextCursor`，只渲染 `items`。

## 2. 错误码

| code | HTTP | message | 场景 |
| --- | --- | --- | --- |
| 0 | 200 | ok | |
| 1001 | 404 | 找不到这位次元住民 | 登录用户不存在 |
| 1002 | 401 | 通行证口令不对哦 | 登录口令错误 |
| 1003 | 422 | 昵称再可爱一点点 | 注册昵称 &lt; 2 |
| 1004 | 422 | 口令至少 4 位 | 注册口令过短 |
| 1005 | 409 | 这个 @ 已经被占用啦 | handle 冲突 |
| 1006 | 401 | 请先登录 | 无 token / 过期 |
| 1007 | 404 | 动态不存在 | |
| 1008 | 404 | 圈子不存在 | |
| 1009 | 404 | 会话不存在 | |
| 1010 | 404 | 住民不存在 | |
| 1011 | 422 | 先写点什么再发布吧 | 动态/评论/私信正文为空 |
| 1012 | 400 | 不能关注自己 | |
| 1013 | 422 | 心情签不合法 | mood 非枚举 |
| 4290 | 429 | 操作太频繁，稍后再试 | 限流 |
| 5000 | 500 | 次元暂时断开了 | 未捕获错误 |

## 3. 鉴权

| 方法 | 路径 | 鉴权 |
| --- | --- | --- |
| POST | `/auth/register` `/auth/login` | 否 |
| 其余 | | 是 |

登录/注册成功返回：

```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "expiresIn": 7200,
  "user": { "$ref": "UserPublic" }
}
```

- `accessToken`：2 小时；`refreshToken`：30 天。
- 客户端把 `accessToken` 存本地，替代现在的 `dimension_link_user_id`。
- `POST /auth/refresh` body：`{ "refreshToken": "..." }`，返回新的 token 对。
- `POST /auth/logout`：作废 refresh。

## 4. 资源对象

### UserPublic

```json
{
  "id": "u_me",
  "nickname": "星野铃",
  "handle": "@hoshi_suzu",
  "bio": "插画练习生 / 偶尔也写一点短篇同人",
  "signature": "今晚也要和星星说晚安。",
  "emoji": "🎀",
  "accentIndex": 0,
  "followers": 1286,
  "following": 86,
  "level": 18,
  "badges": ["绘圈新人王", "樱花祭签到", "次元认证"],
  "isFollowing": false
}
```

`isFollowing`：当前用户是否已关注该住民；看自己时为 `false`。

`GET /me` 另可带 `joinedCircleIds: ["c_doujin", "c_cos", "c_anime"]`。

### PostCard

```json
{
  "id": "p1",
  "author": { "$ref": "UserPublic" },
  "content": "漫展返图来啦～...",
  "createdAt": "2026-09-08T10:00:00Z",
  "mood": "excited",
  "circle": {
    "id": "c_cos",
    "name": "COSPLAY",
    "emoji": "👗"
  },
  "imageHue": 330,
  "imageTitle": "樱色舞台",
  "likeCount": 3,
  "starCount": 1,
  "commentCount": 2,
  "liked": true,
  "starred": false
}
```

`mood` 只传 key：`happy` | `excited` | `sleepy` | `love` | `sad` | `fire`。

### CommentItem

```json
{
  "id": "c1",
  "user": { "$ref": "UserPublic" },
  "content": "裙撑绝了，下一场还出这个吗？",
  "createdAt": "2026-09-08T10:20:00Z"
}
```

### CircleItem

```json
{
  "id": "c_doujin",
  "name": "同人创作",
  "emoji": "✒️",
  "desc": "短篇、长篇、CP 考古，文字与分镜都在这里碰头。",
  "memberCount": 12840,
  "accentIndex": 1,
  "tags": ["乙女", "群像", "无CP", "连载"],
  "joined": true
}
```

### ConversationItem

```json
{
  "id": "cv1",
  "peer": { "$ref": "UserPublic" },
  "unread": 1,
  "lastMessage": {
    "id": "m3",
    "senderId": "u_sakurai",
    "text": "太好了，我在西区 Cos 舞台附近等你。",
    "createdAt": "2026-09-08T13:20:00Z"
  }
}
```

无消息时 `lastMessage` 为 `null`。

### ChatMessageItem

```json
{
  "id": "m2",
  "senderId": "u_me",
  "text": "来！我带新画的小立牌。",
  "createdAt": "2026-09-08T08:10:00Z"
}
```

### NoticeItem

```json
{
  "id": "n2",
  "title": "月见黑 收藏了你的动态",
  "body": "「行星发卡」被收入对方的星标匣。",
  "createdAt": "2026-09-08T01:00:00Z",
  "kind": "star"
}
```

`kind`：`badge` | `star` | `circle` | `like` | `follow` | `comment`。

---

## 5. 接口一览

| 方法 | 路径 | 对应客户端 |
| --- | --- | --- |
| POST | `/auth/register` | `register` |
| POST | `/auth/login` | `login` |
| POST | `/auth/refresh` | 会话续期 |
| POST | `/auth/logout` | `logout` |
| GET | `/me` | `restoreSession` / 我的 |
| PATCH | `/me` | `updateProfile` |
| GET | `/users/{userId}` | `UserProfileScreen` |
| POST | `/users/{userId}/follow` | `toggleFollow` |
| GET | `/posts` | 广场 / 用户动态 / 圈子动态 |
| GET | `/posts/{postId}` | 动态详情 |
| POST | `/posts` | `composePost` |
| POST | `/posts/{postId}/like` | `toggleLike` |
| POST | `/posts/{postId}/star` | `toggleStar` |
| GET | `/posts/{postId}/comments` | 详情留言板 |
| POST | `/posts/{postId}/comments` | `addComment` |
| GET | `/circles` | 圈子 Tab |
| GET | `/circles/{circleId}` | 圈子详情头图信息 |
| POST | `/circles/{circleId}/join` | `toggleJoinCircle` |
| GET | `/conversations` | 消息-私信列表 |
| POST | `/conversations` | `ensureConversation` |
| GET | `/conversations/{id}/messages` | 聊天记录 |
| POST | `/conversations/{id}/messages` | `sendMessage` |
| POST | `/conversations/{id}/read` | `markConversationRead` |
| GET | `/notices` | 消息-通知 |
| GET | `/search` | `SearchScreen` |

---

## 6. 认证

### POST `/auth/register`

```json
{ "nickname": "星野铃", "handle": "suzu", "password": "123456" }
```

- `handle` 不要强求带 `@`，服务端规范化为 `@suzu`。
- 成功 200，`data` 同登录（token + user）。注册成功即登录。

### POST `/auth/login`

```json
{ "identifier": "星野铃", "password": "123456" }
```

`identifier` 可为昵称、`hoshi_suzu`、`@hoshi_suzu`。

---

## 7. 当前用户与住民

### GET `/me`

返回 `UserPublic` + `joinedCircleIds`。

### PATCH `/me`

```json
{ "nickname": "星野铃", "bio": "...", "signature": "..." }
```

只更新传入字段。`handle`、`emoji`、`level`、`badges` 本期只读。

### GET `/users/{userId}`

返回该住民 `UserPublic`（含 `isFollowing`）。

### POST `/users/{userId}/follow`

无 body。Toggle。

```json
{ "isFollowing": true, "followers": 22101 }
```

关注自己 → 1012。

---

## 8. 动态

### GET `/posts`

Query：

| 参数 | 说明 |
| --- | --- |
| cursor / limit | 分页 |
| authorId | 某人的动态（我的 / 他人主页） |
| circleId | 圈子详情 |
| 都不传 | 广场时间线 |

`data.items[]` 为 `PostCard`，倒序。

### GET `/posts/{postId}`

`PostCard`。可另带 `comments` 前 N 条；完整评论用下面列表接口。

### POST `/posts`

```json
{
  "content": "今日速写：把发卡画成了小行星环。",
  "circleId": "c_art",
  "mood": "happy",
  "imageTitle": "行星发卡",
  "imageHue": 312
}
```

- `content` 必填。
- `imageTitle` 空或省略 → `今日速记`。
- `imageHue` 省略 → 服务端随机 0–359。
- 返回完整 `PostCard`。

### POST `/posts/{postId}/like`

Toggle。返回 `{ "liked": true, "likeCount": 4 }`。

### POST `/posts/{postId}/star`

Toggle。返回 `{ "starred": true, "starCount": 2 }`。  
星标他人动态时给作者写 `kind=star` 通知。

### GET `/posts/{postId}/comments`

分页，时间**正序**（与详情页从上往下一致）。

### POST `/posts/{postId}/comments`

```json
{ "content": "星星眼睛好会！求妆造分享～" }
```

返回新建 `CommentItem`。建议给作者写 `kind=comment` 通知（自己评自己不发）。

---

## 9. 圈子

### GET `/circles`

全量即可（目前 6 个）。每项含 `joined`。

### GET `/circles/{circleId}`

单个 `CircleItem`。

### POST `/circles/{circleId}/join`

Toggle。返回 `{ "joined": true, "memberCount": 12841 }`。

---

## 10. 私信与通知

### GET `/conversations`

当前用户会话列表。建议按 `lastMessage.createdAt` 倒序，无消息的按会话 `createdAt` 倒序。每项含 `unread`。客户端底部角标 = 各项 `unread` 之和。

### POST `/conversations`

```json
{ "peerId": "u_sakurai" }
```

已存在则返回已有会话，不新建。返回 `ConversationItem`。

### GET `/conversations/{id}/messages`

分页，建议时间正序（聊天气泡从上到下）。校验当前用户是会话成员。

### POST `/conversations/{id}/messages`

```json
{ "text": "来！我带新画的小立牌。" }
```

返回 `ChatMessageItem`。发送方该会话未读清零；对方未读 +1。

### POST `/conversations/{id}/read`

无 body。返回 `{ "unread": 0 }`。

### GET `/notices`

当前用户通知，时间倒序。

---

## 11. 搜索

### GET `/search?q=`

| 参数 | 说明 |
| --- | --- |
| q | 关键词，可为空 |
| limit | 每类条数，默认 20 |

```json
{
  "users": [ { "$ref": "UserPublic" } ],
  "circles": [ { "$ref": "CircleItem" } ],
  "posts": [ { "$ref": "PostCard" } ]
}
```

匹配规则见需求文档 6.6。空 `q` 返回最新动态 + 全量圈子 + 部分住民，以兼容现搜索页空态。

---

## 12. 客户端改造要点（对接时）

1. 用 `accessToken` 替换 `SharedPreferences` 里的 `dimension_link_user_id`。
2. `Post.likedBy` / `starredBy` 数组改为 `liked` / `starred` + count，避免全量 id 列表。
3. 列表接口的 `author` / `circle` / `peer` 做成嵌套对象，减少 N+1。
4. 所有 toggle 以响应里的布尔值为准，不要本地猜状态。
5. P1 再加 `imageUrl`、`avatarUrl`；有值则客户端优先显示真实图，否则继续用 hue/emoji。

## 13. 本地联调

```
POST /v1/auth/login
{ "identifier": "星野铃", "password": "123456" }
```

开发环境种子用户口令均为 `123456`。圈子 id 必须与需求文档种子表一致，否则发布页 `ChoiceChip` 和 mock 迁移会对不上。
