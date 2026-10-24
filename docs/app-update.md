# GitHub 检查更新

2026-10-24：设置 → 关于 MixMusic → 检查更新。

实现集中在 `lib/page/setting/update/`：UpdateController 自己持有网络客户端、版本信息和检查状态，页面创建并销毁它。没有注册到全局容器，不依赖插件管理、播放、音乐下载、数据库或其他业务控制器。移除页面路由、设置入口与该目录即可拆除功能。

检查由用户手动触发，不在启动或后台轮询。使用 package_info_plus 读取实际安装版本、pub_semver 比较版本、lemon_net 请求 GitHub、url_launcher 打开系统浏览器。完整错误打印到 `[Update]` 控制台日志，界面显示中文原因；请求超时、限流或无法访问不会显示成“已是最新”。

页面可选择“正式版”或“测试版（含正式版）”，默认正式版，选择通过 SP 的 `updateChannel` 保存，重新打开或重启后恢复。控制器自行读取设置，不依赖 SettingController。切换后清除旧检查结果，检查过程中禁用渠道选择。

## 发布约定

- 仓库：`yhsj0919/MixMusic`。正式渠道使用 `GET /repos/yhsj0919/MixMusic/releases/latest`，读取仓库标记为 Latest 的正式 Release，不按分支筛选，也不自行选取版本号最高的发布。
- 测试渠道使用 `GET /repos/yhsj0919/MixMusic/releases?per_page=100`，从最近 100 条正式与预发行 Release 中选取版本号最高的版本，忽略草稿和无效版本标签。正式版本优先于同版本的 beta/rc，beta.10 正确高于 beta.2。
- 创建正式 Release 并标记为 Latest，标签如 `v0.2.0`，与该次构建的 pubspec 版本对应。只推 Git 标签而未创建 Release 不会被检测。
- 接口 404 或渠道无有效发布时显示“暂未获取到所选渠道的发布版本”，可打开发布页确认；GitHub 对没有 Latest 和仓库不可访问都可能返回 404，界面不宣称已是最新。同版本或较旧版本不提示更新。正式 Latest 响应若异常包含草稿、预发行或无效版本标签，按检查失败处理。
- Release 正文作为更新说明。已上传的附件显示名称、大小和 browser_download_url，用户选择对应平台附件，通过浏览器下载；无附件时可打开发布页。

本轮实现检查、说明及外部下载入口，尚未实现应用内下载进度、下载校验、安装和重启替换程序。

在线构建与 Release 发布见 [发布工作流](release-workflow.md)，Android/Windows 附件统一使用 `MixMusic-系统-架构-v版本号` 命名。正式发布标记 Latest，预发布供测试渠道获取。

## 验证

11 项本机 HTTP 功能测试覆盖 Latest 端点及非 v2 分支响应、测试渠道的 beta 数字排序和草稿过滤、渠道保存与恢复、切换后清除旧结果、附件读取、同版与降级排除、同版本构建号、缺失发布、限流失败后重试、异常版本及响应、重复检查合并、销毁中断和链接协议检查。静态检查通过，此前新增原生依赖已通过 Android Release Kotlin 编译。直连 GitHub 时当前出口触发 API 限流，尚未取得真实 Release 成功响应；没有把模拟数据当作真实发布。系统浏览器跳转及 Android/Windows 页面仍待设备验证，未打包。

接口依据：[GitHub Latest Release REST 文档](https://docs.github.com/en/rest/releases/releases#get-the-latest-release)。
