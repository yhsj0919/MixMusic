import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PageNestedScrollView extends StatelessWidget {
  PageNestedScrollView({
    Key? key,
    this.onRefresh,
    this.onLoad,
    required this.controller,
    required this.headerSliverBuilder,
    required this.body,
    this.scrollController,
  }) : super(key: key);

  final FutureOr Function()? onRefresh;
  final FutureOr Function()? onLoad;

  EasyRefreshController controller;
  ScrollController? scrollController;
  final NestedScrollViewHeaderSliversBuilder headerSliverBuilder;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return EasyRefresh(
        header: const MaterialHeader(),
        footer: const ClassicFooter(
          dragText: '拉动加载',
          readyText: '释放加载',
          processingText: '正在加载...',
          processedText: "加载完成",
          failedText: '加载失败',
          noMoreText: '没有更多数据',
          messageText: '更新于 %T',
          hapticFeedback: true,
        ),
        controller: controller,
        onRefresh: onRefresh,
        onLoad: onLoad,
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: scrollController,
          headerSliverBuilder: headerSliverBuilder,
          body: body,
        ));
  }
}

typedef RefreshCallback = Future<void> Function();
typedef LoadMoreCallback = Future Function();
