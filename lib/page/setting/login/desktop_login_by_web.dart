import 'dart:collection';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_music/common/api/api_factory.dart';
import 'package:mix_music/common/api/music_api.dart';
import 'package:mix_music/common/entity/plugins_info.dart';
import 'package:mix_music/page/setting/login/user_controller.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:url_launcher/url_launcher.dart';

class DesktopLoginByWebPage extends StatefulWidget {
  const DesktopLoginByWebPage({super.key, required this.plugin});

  final PluginsInfo? plugin;

  @override
  State<DesktopLoginByWebPage> createState() => _DesktopLoginByWebPageState();
}

class _DesktopLoginByWebPageState extends State<DesktopLoginByWebPage> {
  MusicApi? api;
  RxnString cookie = RxnString();
  UserController userController = Get.put(UserController());
  PluginsInfo? plugin;

  ThemeController theme = Get.put(ThemeController());

  final GlobalKey webViewKey = GlobalKey();

  RxBool webInit = RxBool(false);

  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
    userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0",
  );

  // late ContextMenu contextMenu;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  RxnString myCookie = RxnString();
  RxnString myUrl = RxnString();

  @override
  void initState() {
    super.initState();

    plugin = widget.plugin;

    api = ApiFactory.api(package: plugin?.package ?? "");

    webInit.stream.listen((v) {
      api?.getWebLoginUrl().then((v) {
        myUrl.value = v;
        print(v);
        var url = WebUri(v);
        webViewController?.loadUrl(urlRequest: URLRequest(url: url));
      });
    });
  }

  @override
  void dispose() {
    webViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text("网页登陆"),
        leading: Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
          child: IconButton(
            icon: Icon(FluentIcons.back),
            onPressed: () {
              context.pop();
            },
          ),
        ),
        commandBar: Row(
          spacing: 8,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(FluentIcons.chrome_back, size: 18),
              onPressed: () {
                webViewController?.goBack();
              },
            ),
            IconButton(
              icon: Icon(FluentIcons.chrome_back_mirrored, size: 18),
              onPressed: () {
                webViewController?.goForward();
              },
            ),
            IconButton(
              icon: Icon(FluentIcons.refresh, size: 18),
              onPressed: () {
                webViewController?.reload();
              },
            ),
            Obx(
              () => Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      var temp = myCookie.value ?? "";
                      showDialog<String>(
                        context: context,
                        builder: (context) => ContentDialog(
                          title: const Text('当前Cookie'),
                          content: SingleChildScrollView(child: Text(temp)),
                          actions: [
                            Button(
                              child: const Text('关闭'),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            FilledButton(
                              child: const Text('保存校验'),
                              onPressed: () {
                                api?.setCookie(cookie: temp);
                                userController.getAllUser();
                                api
                                    ?.userInfo()
                                    .then((v) {
                                      var user = v.data;
                                      showFluentInfo(context, "${user?.name ?? ""} ${user?.login == 1 ? "已登录" : "未登录"} ${user?.vip == 1 ? "VIP" : "非VIP"}");
                                    })
                                    .catchError((e) {
                                      showFluentInfo(context, "${e ?? ""} ");
                                    });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(FluentIcons.cake, size: 18),
                  ),
                  myCookie.value?.isNotEmpty == true
                      ? InfoBadge(
                          // label: Text("5"),
                        )
                      : Container(),
                ],
              ),
            ),
          ],
        ),
      ),

      content: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              key: webViewKey,

              // webViewEnvironment: webViewEnvironment,
              // initialUrlRequest: URLRequest(url: WebUri(myUrl.value ?? "")),
              // initialUrlRequest:
              // URLRequest(url: WebUri(Uri.base.toString().replaceFirst("/#/", "/") + 'page.html')),
              // initialFile: "assets/index.html",
              initialUserScripts: UnmodifiableListView<UserScript>([]),
              initialSettings: settings,
              // contextMenu: contextMenu,
              onWebViewCreated: (controller) async {
                webViewController = controller;
                webInit.value = true;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  this.url = url.toString();
                  urlController.text = this.url;
                });
              },
              onPermissionRequest: (controller, request) {
                return PermissionResponse(resources: request.resources, action: PermissionResponseAction.GRANT);
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url!;

                if (!["http", "https", "file", "chrome", "data", "javascript", "about"].contains(uri.scheme)) {
                  if (await canLaunchUrl(uri)) {
                    // Launch the App
                    await launchUrl(uri);
                    // and cancel the request
                    return NavigationActionPolicy.CANCEL;
                  }
                }

                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) {
                setState(() {
                  this.url = url.toString();
                  urlController.text = this.url;
                });
              },
              shouldInterceptRequest: (InAppWebViewController controller, WebResourceRequest request) async {
                var cookie = CookieManager.instance();
                cookie.getCookies(url: WebUri(myUrl.value ?? "")).then((ck) {
                  // print("安卓拦截=====>${ck.map((e) => "${e.name}=${e.value}").join(";")}");

                  if (ck.isNotEmpty) {
                    myCookie.value = ck.map((e) => "${e.name}=${e.value}").join(";");
                  }
                });
                return null;
              },

              onReceivedError: (controller, request, error) {},
              onProgressChanged: (controller, progress) {
                setState(() {
                  this.progress = progress / 100;
                  urlController.text = this.url;
                });
              },
              onUpdateVisitedHistory: (controller, url, isReload) {
                setState(() {
                  this.url = url.toString();
                  urlController.text = this.url;
                });
              },
              onConsoleMessage: (controller, consoleMessage) {
                // print(consoleMessage);
              },
            ),
            progress < 1.0 ? ProgressBar(value: progress) : Container(),
          ],
        ),
      ),
    );
  }
}
