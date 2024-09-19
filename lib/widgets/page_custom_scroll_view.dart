import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PageCustomScrollView extends StatelessWidget {
  PageCustomScrollView({
    Key? key,
    required this.slivers,
    this.onRefresh,
    this.onLoad,
    this.shrinkWrap,
    required this.controller,
    this.scrollController,
  }) : super(key: key);

  final FutureOr Function()? onRefresh;
  final FutureOr Function()? onLoad;

  EasyRefreshController controller;
  ScrollController? scrollController;

  final List<Widget> slivers;

  final bool? shrinkWrap;

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
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: scrollController,
          shrinkWrap: shrinkWrap ?? false,
          slivers: slivers,
        ));
  }
}

typedef RefreshCallback = Future<void> Function();
typedef LoadMoreCallback = Future Function();
