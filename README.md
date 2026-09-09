# 次元链接 Dimension Link

二次元卡通风格的 Flutter 社交应用。住民可以在广场发动态、加入兴趣圈子、互相关注，并用私信把心动寄到平行世界。

当前版本：登录 / 注册 / 广场 / 圈子 / 私信 / 通知 / 搜索都按 [接口文档](docs/backend-api.md) 请求 `API_BASE_URL`。模型字段与 `UserPublic`、`PostCard`、`CircleItem` 等资源对象对齐。无 `ApiClient` 的单元测试仍使用同结构的本地 seed。

非生产环境（开发 / 测试）打包后，左下角有「网络」按钮，可查看每次请求的 URL、状态码、请求体和响应体，方便确认注册有没有真正打到服务器。

## 功能

- 樱花粉 / 星空紫主题，圆角卡片、心情签、插画风配图
- 登录 / 注册（请求后端 `/v1/auth/login`、`/v1/auth/register`）
- 广场动态：点赞、星标、评论、发布
- 圈子：同人、COS、番剧、绘圈、开黑、声优电台
- 私信与系统通知
- 个人主页、编辑资料、搜索住民 / 圈子 / 动态

## 演示账号

- 昵称：`星野铃`
- 口令：`123456`

演示账号需要后端已有对应住民。无后端时，登录/注册会失败，非生产包可点左下角「网络」查看请求详情。

单元测试仍走本地 mock，不依赖服务器。

## 环境变量

通过 `--dart-define-from-file` 在编译期注入环境变量，三套环境互相隔离：

| 环境 | 配置文件 | `APP_ENV` | 默认 API Base URL |
| --- | --- | --- | --- |
| 开发 | `env/development.env` | `dev` | `http://172.28.0.1:8080/v1` |
| 测试 | `env/staging.env` | `staging` | `https://api-staging.dimension-link.dev/v1` |
| 生产 | `env/production.env` | `prod` | `https://api.dimension-link.dev/v1` |

变量说明：

- `APP_ENV`：运行环境，取值 `dev` / `staging` / `prod`（也兼容 `development`、`test`、`production`）
- `API_BASE_URL`：后端 API 基地地址（Base URL），与 [docs/backend-api.md](docs/backend-api.md) 的 `/v1` 约定一致
- `ENABLE_LOGGING`：是否输出调试日志，生产环境为 `false`

未传 `--dart-define-from-file` 时，默认使用开发环境。请按实际后端域名修改 `env/*.env`；含密钥的本地覆盖可放在 `env/*.local.env`（已加入 `.gitignore`）。

代码中读取：

```dart
import 'package:dimension_link/config/app_config.dart';

final url = AppConfig.current.apiBaseUrl;
final isProd = AppConfig.current.isProduction;
```

IDE 可直接使用 `.vscode/launch.json` 里的「开发环境 / 测试环境 / 生产环境」启动项。

## 运行

需要 Flutter SDK 3.5+。本仓库开发时使用 3.47.2。

```bash
flutter pub get

# 开发环境
flutter run --dart-define-from-file=env/development.env -d chrome
# 测试环境
flutter run --dart-define-from-file=env/staging.env -d chrome
# 生产环境配置（调试用）
flutter run --dart-define-from-file=env/production.env -d chrome
```

也可省略 `--dart-define-from-file`，效果与开发环境相同：

```bash
flutter run -d chrome
# 或
flutter run -d edge
flutter run -d windows
```

国内网络建议：

```bash
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

## 测试

```bash
flutter test
# 分别验证测试 / 生产环境的编译注入
flutter test --dart-define-from-file=env/staging.env
flutter test --dart-define-from-file=env/production.env
```

## 打包

打包必须带上对应环境的 `--dart-define-from-file`，否则会落入开发环境默认值。推荐用脚本（会把产物复制到 `release/`，文件名带环境后缀）：

```powershell
# Android APK：开发 / 测试 / 生产
.\scripts\package.ps1 -Env dev -Target apk
.\scripts\package.ps1 -Env staging -Target apk
.\scripts\package.ps1 -Env prod -Target apk

# Android App Bundle、Windows、Web（同样注入环境变量）
.\scripts\package.ps1 -Env prod -Target appbundle
.\scripts\package.ps1 -Env prod -Target windows
.\scripts\package.ps1 -Env prod -Target web
```

IDE 也可使用「运行任务」里的「打包 APK · 开发/测试/生产环境」。

等价手写命令：

```bash
flutter build apk --release --dart-define-from-file=env/development.env
flutter build apk --release --dart-define-from-file=env/staging.env
flutter build apk --release --dart-define-from-file=env/production.env

flutter build windows --release --dart-define-from-file=env/production.env
flutter build web --release --dart-define-from-file=env/production.env
```

产物示例（版本号来自 `pubspec.yaml`）：

- APK：`release/dimension-link-1.0.0-dev.apk` / `-staging.apk` / `-prod.apk`
- AAB：`release/dimension-link-1.0.0-prod.aab`
- Windows：`release/dimension-link-1.0.0-prod-windows/`
- Web：`release/dimension-link-1.0.0-prod-web/`

Android 打包需要 JDK 17 与 Android SDK（compileSdk 36）。把 APK 传到手机后，允许「未知来源」即可安装。当前 release 使用 debug 签名，适合内测安装；上架应用商店前需要换成正式 keystore。

开发 / 测试包左下角有「网络」调试按钮；生产包不会带这个入口。口令、token 在面板里会打码。
