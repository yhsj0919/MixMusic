# GitHub 检查更新

2026-10-24：设置 → 关于 MixMusic → 检查更新。

实现集中在 `lib/page/setting/update/`：UpdateController 自己持有网络客户端、版本信息和检查状态，页面创建并销毁它。没有注册到全局容器，不依赖插件管理、播放、音乐下载、数据库或其他业务控制器。移除页面路由、设置入口与该目录即可拆除功能。

检查由用户手动触发，不在启动或后台轮询。使用 package_info_plus 读取实际安装版本、pub_semver 比较版本、lemon_net 请求 GitHub、url_launcher 打开系统浏览器。完整错误打印到 `[Update]` 控制台日志，界面显示中文原因；请求超时、限流或无法访问不会显示成“已是最新”。

页面可选择“正式版”或“测试版（含正式版）”，默认正式版，选择通过 SP 的 `updateChannel` 保存，重新打开或重启后恢复。控制器自行读取设置，不依赖 SettingController。切换后清除旧检查结果，检查过程中禁用渠道选择。

## 发布约定

- 仓库：`yhsj0919/MixMusic`。App 直接读取 `https://raw.githubusercontent.com/yhsj0919/MixMusic/updates/stable.json` 或 `preview.json`，不调用 GitHub REST API，不需要 Token。
- 正式清单保存仓库标记为 Latest 的正式 Release，暂无正式版本时为 JSON `null`。
- 测试清单保存最近 100 条非草稿 Release，客户端过滤无效版本标签并选择最高版本，含正式与预发布版本。
- JSON 保留 Release 的标签、说明、附件名称、大小和下载地址。raw 返回 text/plain 时也按 JSON 解码。
- Actions 先完成安装包上传和正式发布，再通过一次 Git 提交同时更新两个清单；独立 `updates` 分支不触发构建。发布作业串行执行，避免并发覆盖清单。
- 修改、删除 Release 或手动切换 Latest 后需重新生成清单；只推标签或只构建不发布，不更新清单。
- 清单缺失、正式版为 null 或测试列表为空时提示暂无发布；网络及解析失败按错误显示，不宣称已是最新。
- 同版本或较旧版本不提示更新；附件继续通过系统浏览器下载。

本轮实现检查、说明及外部下载入口，尚未实现应用内下载进度、下载校验、安装和重启替换程序。

在线构建与 Release 发布见 [发布工作流](release-workflow.md)，Android/Windows 附件统一使用 `MixMusic-系统-架构-v版本号` 命名。正式发布标记 Latest，预发布供测试渠道获取。

## 验证

12 项本机 HTTP 功能测试覆盖静态渠道路径、text/plain JSON 解码、空清单、版本排序、渠道保存、错误恢复及生命周期。发布脚本 14 项测试覆盖渠道清单、草稿过滤、首次创建分支和非强制更新、附件上传失败不发布。
