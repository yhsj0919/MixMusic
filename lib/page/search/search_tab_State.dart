import 'package:flutter/material.dart';
import 'package:mix_music/widgets/message.dart';

abstract class SearchTabPageState<T extends StatefulWidget> extends State<T> {
  void search({required String keyword}) {}
}

class SearchPageController {
  var pages = <String, SearchTabPageState?>{};

  String? keyword;

  void addState(String package, SearchTabPageState tabState) {
    pages[package] = tabState;
  }

  void search({required String keyword}) {
    if (keyword.isEmpty) {
      showError("请输入关键字");
      return;
    }

    this.keyword = keyword;
    pages.forEach((key, value) {
      value?.search(keyword: keyword);
    });
  }
}
