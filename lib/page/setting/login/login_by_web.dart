import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/api_factory.dart';
import 'package:mix_music/api/music_api.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/setting/user_controller.dart';
import 'package:mix_music/theme/theme_controller.dart';
import 'package:mix_music/widgets/message.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginByWebPage extends StatefulWidget {
  const LoginByWebPage({super.key});

  @override
  State<LoginByWebPage> createState() => _LoginByWebPageState();
}

class _LoginByWebPageState extends State<LoginByWebPage> {
  MusicApi? api;
  RxnString cookie = RxnString();
  UserController userController = Get.put(UserController());
  PluginsInfo? plugin;

  ThemeController theme = Get.put(ThemeController());

  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true,
      userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0");

  late ContextMenu contextMenu;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  RxnString myCookie = RxnString();
  RxnString myUrl = RxnString();

  @override
  void initState() {
    super.initState();

    plugin = Get.arguments;

    api = ApiFactory.api(package: plugin?.package ?? "");

    contextMenu = ContextMenu(
        menuItems: [
          ContextMenuItem(
              id: 1,
              title: "Special",
              action: () async {
                // print("Menu item Special clicked!");
                // print(await webViewController?.getSelectedText());
                await webViewController?.clearFocus();
              })
        ],
        settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: false),
        onCreateContextMenu: (hitTestResult) async {
          // print("onCreateContextMenu");
          // print(hitTestResult.extra);
          // print(await webViewController?.getSelectedText());
        },
        onHideContextMenu: () {
          // print("onHideContextMenu");
        },
        onContextMenuActionItemClicked: (contextMenuItemClicked) async {
          var id = contextMenuItemClicked.id;
          // print("onContextMenuActionItemClicked: " +
          //     id.toString() +
          //     " " +
          //     contextMenuItemClicked.title);
        });

    Future.delayed(Duration(milliseconds: 400)).then((v) {
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text("网页登陆"),
        toolbarHeight: 64,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              webViewController?.goBack();
            },
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              webViewController?.goForward();
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              webViewController?.reload();
            },
          ),
          Obx(() => Badge(
                // label: Text("5"),
                isLabelVisible: myCookie.value?.isNotEmpty == true,
                child: IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          var temp = myCookie.value ?? "";

                          return AlertDialog(
                            title: const Text('当前Cookie'),
                            content: SingleChildScrollView(
                              child: Text(temp),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('保存校验'),
                                onPressed: () {
                                  api?.setCookie(cookie: temp);
                                  api?.userInfo().then((v) {
                                    var user = v.data;
                                    showInfo("${user?.name ?? ""} ${user?.login == 1 ? "已登录" : "未登录"} ${user?.vip == 1 ? "VIP" : "非VIP"}");
                                  });
                                },
                              ),
                              TextButton(
                                child: const Text('关闭'),
                                onPressed: () {
                                  Navigator.of(context).pop(); // 关闭对话框
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.cookie)),
              )),
        ],
      ),
      body: SafeArea(
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
              contextMenu: contextMenu,
              onWebViewCreated: (controller) async {
                webViewController = controller;
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
                    await launchUrl(
                      uri,
                    );
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
            progress < 1.0 ? LinearProgressIndicator(value: progress) : Container(),
          ],
        ),
      ),
    );
  }
}
