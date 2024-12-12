import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PageGridView extends StatefulWidget {
  PageGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onRefresh,
    this.onLoad,
    this.padding,
    required this.gridDelegate,
    this.shrinkWrap,
    required this.controller,
    this.scrollController,
  });

  final FutureOr Function()? onRefresh;
  final FutureOr Function()? onLoad;
  final int itemCount;

  EasyRefreshController controller;
  ScrollController? scrollController;

  final IndexedWidgetBuilder itemBuilder;

  final EdgeInsetsGeometry? padding;
  final SliverGridDelegate gridDelegate;
  final bool? shrinkWrap;

  @override
  State<PageGridView> createState() => _PageGridViewState();
}

class _PageGridViewState extends State<PageGridView> {
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
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: widget.scrollController,
          shrinkWrap: widget.shrinkWrap ?? false,
          itemCount: widget.itemCount,
          padding: widget.padding ?? const EdgeInsets.only(top: 0),
          itemBuilder: (BuildContext context, int index) {
            return widget.itemBuilder(context, index);
          },
          gridDelegate: widget.gridDelegate,
        ));
  }
}

typedef RefreshCallback = Future<void> Function();
typedef LoadMoreCallback = Future Function();
