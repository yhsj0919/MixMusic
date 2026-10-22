# 插件日志

设置中的插件日志入口打开 Lemon UI 弹窗。日志实时更新，包含插件 ID、时间、级别和内容，支持清空、复制；加载失败时首页也提供查看入口。

目前记录默认 Core Runtime 的 console.log、console.warn、console.error，以及加载过程和加载错误堆栈。内存保留最近 500 条，暂不持久化。单插件查看入口可指定 pluginId。

lemon_js_extensions 增加可选日志回调，安装与恢复均按插件 ID 透传。JSUI 日志后续接入，当前不宣称覆盖插件 UI。

真实插件源码与平台相关日志规则由独立插件仓库维护。
