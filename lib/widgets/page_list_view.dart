import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PageListView extends StatefulWidget {
  PageListView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.onRefresh,
    this.onLoad,
    this.padding,
    this.itemExtent,
    this.shrinkWrap,
    required this.controller,
    this.scrollController,
  }) : super(key: key);

  final FutureOr Function()? onRefresh;
  final FutureOr Function()? onLoad;
  final int itemCount;

  EasyRefreshController controller;
  ScrollController? scrollController;

  final IndexedWidgetBuilder itemBuilder;

  final EdgeInsetsGeometry? padding;
  final double? itemExtent;
  final bool? shrinkWrap;

  @override
  State<PageListView> createState() => _PageListViewState();
}

class _PageListViewState extends State<PageListView> {
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
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: widget.scrollController,
          shrinkWrap: widget.shrinkWrap ?? false,
          itemCount: widget.itemCount,
          padding: widget.padding,
          itemExtent: widget.itemExtent,
          itemBuilder: (BuildContext context, int index) {
            return widget.itemBuilder(context, index);
          },
        ));
  }
}

typedef RefreshCallback = Future<void> Function();
typedef LoadMoreCallback = Future Function();
