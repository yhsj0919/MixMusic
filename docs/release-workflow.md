# 在线构建与发布

工作流：`.github/workflows/release.yml`，在 GitHub Actions 中显示为“在线打包并发布”。发布脚本集中在 `tool/release.mjs`，不依赖 App 控制器。

## 使用

1. 把工作流、发布脚本及需要打包的 App 代码提交并推送到 GitHub。`workflow_dispatch` 的工作流文件需要先存在于默认分支；运行时在 **Use workflow from** 选择实际要打包的分支，例如 `v2`。
2. 配置下文的 Android 签名 Secrets。仅构建 Windows 时不需要 Android 密钥。
3. Actions → 在线打包并发布 → Run workflow。
4. 选择 `prerelease`（预发布）或 `stable`（正式发布），填写版本和平台。初次验证可取消 `publish`，只获取 Actions 产物。

版本示例：

- 正式：填写 `0.2.0`，发布标签为 `v0.2.0`，标记为 GitHub Latest。
- 预发布：填写 `0.2.0-beta.1`，发布标签为 `v0.2.0-beta.1`，标记 Prerelease，不替换 Latest。
- 预发布只填写 `0.2.0` 时，自动补为 `0.2.0-beta.<构建号>`。
- 版本留空读取 pubspec，构建号留空使用工作流运行序号。版本通过 Flutter build-name/build-number 写入安装包，不修改源码里的 pubspec。
- 构建号使用递增整数；从正式版更新到测试版时，需要更高的基础版本，例如 `0.1.0` → `0.2.0-beta.1`，同版本的 beta 按版本规则低于正式版。
- 已存在的标签不会覆盖。上传失败可能保留未公开的 Release 草稿，检查并删除该草稿后重试，或使用新版本号。

当前覆盖 Android、Windows，可选择一起构建或单独构建。macOS、Linux、iOS 未接入本工作流。

## 安装包命名

以 `v0.2.0` 为例：

| 附件 | 用途 |
| --- | --- |
| `MixMusic-android-arm64-v0.2.0.apk` | Android arm64-v8a |
| `MixMusic-android-armv7-v0.2.0.apk` | Android armeabi-v7a |
| `MixMusic-android-x64-v0.2.0.apk` | Android x86_64 |
| `MixMusic-windows-x64-v0.2.0-setup.exe` | Windows x64 安装包，含快捷方式与卸载入口 |
| `MixMusic-windows-x64-v0.2.0.zip` | Windows x64，含 exe、DLL、VC++ 运行库和 data 完整目录 |
| `SHA256SUMS` | 安装包 SHA-256 校验值 |

所有选中平台构建成功后才进入发布作业：先创建草稿，上传全部安装包和校验文件，再公开发布。构建失败不会发布半成品；`publish` 取消勾选时只保留 Actions 附件。

Windows 安装器参考 V1 使用的 Flutter Distributor（现名 [Fastforge](https://github.com/fastforgedev/fastforge)）调用 Inno Setup 的流程。当前 Actions 直接使用 `windows/packaging/exe/setup.iss` 调用 ISCC，不依赖旧名称的 CLI。打包完整 Release 目录及 VC++ 运行库，生成 EXE 与 ZIP 两种格式。V2 的安装标识为 `MixMusic.v2`，安装目录为 `MixMusic v2`，独立于 V1 的安装标识；后续 V2 安装器沿用该标识进行覆盖升级。安装器提供桌面/开始菜单快捷方式及卸载入口，不默认启动程序，不配置开机自启。

安装器默认简体中文，也可选择英文。中文语言文件随仓库提供，来自 [Inno Setup 官方仓库](https://github.com/jrsoftware/issrc/blob/7d30127fdb2ca8b7c0617e8d616e8625bf6ecd99/Files/Languages/ChineseSimplified.isl)。Windows 应用和安装器暂时复用 V1 的图标，后续再统一替换。

CI 使用 runner 上的 Inno Setup 6，缺失时通过 Chocolatey 安装。本机可用 `INNO_SETUP_COMPILER` 指定 `ISCC.exe` 完整路径。Windows 版本数字及构建号需不大于 65535，安装器显示的版本仍保留 beta/rc 后缀。

## Android 签名

同一应用覆盖更新需要使用相同签名。云构建不能依赖每台 runner 临时生成的 debug 密钥，所以 Android 构建必须配置固定密钥。

当前按用户要求复用 V1 的 `MixMusic.jks`。本机密钥放在 `key/MixMusic.jks`，签名配置放在 `android/key.properties`，两者都被 Git 忽略。本机 Release 默认读取该配置，CI 的 `ANDROID_KEYSTORE_PATH` 与签名环境变量优先。没有把 V1 的密码复制到 Gradle 或工作流源码。

依次执行以下命令，每执行一次，就把剪贴板内容粘贴到 GitHub **Settings → Secrets and variables → Actions** 中同名 Secret：

```powershell
./tool/copy-android-secret.ps1 ANDROID_KEYSTORE_BASE64
./tool/copy-android-secret.ps1 ANDROID_KEYSTORE_PASSWORD
./tool/copy-android-secret.ps1 ANDROID_KEY_ALIAS
./tool/copy-android-secret.ps1 ANDROID_KEY_PASSWORD
```

脚本从本机签名配置读取，不在终端打印凭据，也不会自动上传。每次复制后先粘贴再运行下一条。2026-10-24 已将四个 Secrets 加密配置到 `yhsj0919/MixMusic` 并核对名称，云端构建可使用同一把 V1 密钥；更换仓库时需要重新配置。

若将来决定更换新密钥，可在 PowerShell 执行（密码交互输入）：

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.mixmusic" | Out-Null
& "$env:JAVA_HOME\bin\keytool.exe" -genkeypair -v -storetype JKS -keystore "$env:USERPROFILE\.mixmusic\mixmusic-release.jks" -alias mixmusic -keyalg RSA -keysize 2048 -validity 10000
```

`keytool` 随 JDK 提供，本机也可使用 `D:\Develop\java\bin\keytool.exe`。别名密码可以在提示时直接回车，使用与密钥库相同的密码。

将文件编码后复制到剪贴板：

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\.mixmusic\mixmusic-release.jks")) | Set-Clipboard
```

在仓库 **Settings → Secrets and variables → Actions → New repository secret** 添加：

| Secret | 值 |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | V1 密钥文件的完整 Base64 内容 |
| `ANDROID_KEYSTORE_PASSWORD` | V1 密钥库密码，由复制脚本读取 |
| `ANDROID_KEY_ALIAS` | V1 别名，由复制脚本读取 |
| `ANDROID_KEY_PASSWORD` | V1 别名密码，由复制脚本读取 |

密钥、密码分别备份，密钥文件不提交到 Git。新生成密钥时，Secrets 应改用新文件、别名和密码；新建命令示例的别名为 `mixmusic`。

### 与已安装版本的关系

当前已安装的 V2 测试版若是 debug 签名，首次换成 V1 密钥后不能直接覆盖，需要卸载后安装；卸载会清除该应用数据。之后持续使用 V1 密钥即可签名一致。V1 包名为 `site.mix.mix_music`，当前 V2 包名为 `com.example.mix_music.v2`，复用密钥并不改变包名，两者仍会并存。可用 `android/gradlew signingReport` 确认实际签名配置。

## Git 仓库依赖

App 的 Lemon 系列依赖直接从 GitHub 获取，`pubspec.yaml` 使用完整提交 SHA，`pubspec.lock` 记录解析结果。本机与 Actions 使用相同配置，不再要求克隆依赖到相邻目录。

- 更新依赖时，先在对应仓库提交推送，再更新 `pubspec.yaml` 的 `ref`，执行 `flutter pub get` 并提交锁文件。
- `quickjs` 的四个包使用同一提交；`lemon_js` 和 `lemon_js_ui` 的 Git overrides 用于统一其传递依赖来源。
- `lemon_audio` 仓库自带 Windows 修复依赖，无需本机额外目录或宿主 override。
- `lemon_audio` 当前为私有仓库。配置仓库 Secret `DEPENDENCIES_TOKEN`，使用仅选择 `lemon_audio`、授予 Contents 只读权限的 fine-grained PAT。当前仓库的 `GITHUB_TOKEN` 无法读取另一私有仓库。安装依赖步骤通过进程环境中的 Git credential helper 使用令牌，不写入 Git 配置或依赖 URL；令牌不传给后续编译步骤。
- `flutter pub get --enforce-lockfile` 保持 pubspec.lock 的依赖版本；依赖仓库变更了约束时需先在本机更新锁文件再提交，CI 不静默升级。
- 本轮固定 Flutter `3.47.7`，与本机版本及 Dart `3.13.5` 约束一致。

## 更新日志

主要面向用户的中文日志写在根目录 `CHANGELOG.md` 的 `## [Unreleased]` 下，例如：

```markdown
## [Unreleased]

### 新增
- 支持检查正式版和测试版更新。

### 修复
- 修复重启后继续播放未加载歌词的问题。
```

工作流提取这段文字，并追加本次输入的 `notes`。更早版本章节不混入新日志。Release 创建时再让 GitHub 补充自动生成的 PR/比较记录；`.github/release.yml` 配置了“新增功能”“问题修复”“维护与其他调整”分类。直接提交的改动仍以手写中文日志为准，不能依赖 PR 自动分类补齐。

正式版发布后，手动把已发布的 Unreleased 内容移动到 `## [版本号] - 日期` 下，并留出空的 Unreleased，避免下次重复发布旧日志。工作流不会自动提交或重写更新日志。

## 验证范围

12 项发布脚本功能测试与 actionlint 静态检查通过，包含真实 Inno Setup 编译预发行安装器夹具、EXE 附件的上传和校验值；该编译只用于验证安装脚本，未运行安装器，不代表已打出当前 App 的正式安装包。Android Gradle 签名配置本机编译及 V1 签名检查通过。没有推送、触发云构建或创建真实 Release。云端平台编译、签名 Secret 配置与最终安装覆盖需首次 Actions 运行验证。

参考：[手动触发工作流](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow)、[GitHub Release API](https://docs.github.com/en/rest/releases/releases#create-a-release)、[Flutter Android 签名](https://docs.flutter.dev/deployment/android#sign-the-app)。
