import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PageSliverView extends StatefulWidget {
  PageSliverView({
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
  State<PageSliverView> createState() => _PageSliverViewState();
}

class _PageSliverViewState extends State<PageSliverView> {
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
        controller: widget.controller,
        onRefresh: widget.onRefresh,
        onLoad: widget.onLoad,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: widget.scrollController,
          shrinkWrap: widget.shrinkWrap ?? false,
          slivers: widget.slivers,
        ));
  }
}

typedef RefreshCallback = Future<void> Function();
typedef LoadMoreCallback = Future Function();
