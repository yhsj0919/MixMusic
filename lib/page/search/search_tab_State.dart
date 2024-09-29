import 'package:flutter/material.dart';



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
    this.keyword = keyword;
    pages.forEach((key, value) {
      value?.search(keyword: keyword);
    });
  }
}
