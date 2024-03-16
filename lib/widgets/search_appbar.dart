import 'package:flutter/material.dart';

class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  SearchAppBar({
    super.key,
    required this.textEditingController,
    this.actions,
    this.bottom,
    this.flexibleSpace,
    this.toolbarHeight,
    this.onSubmitted,
    this.onChanged,
    this.hintText,
  }) : preferredSize = _PreferredAppBarSize(toolbarHeight, bottom?.preferredSize.height);
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? flexibleSpace;
  final double? toolbarHeight;
  final TextEditingController textEditingController;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;
  final String? hintText;

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();

  @override
  final Size preferredSize;
}

class _SearchAppBarState extends State<SearchAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: TextField(
        controller: widget.textEditingController,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: InputBorder.none,
        ),
        autofocus: true,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
      ),
      actions: [
        IconButton(
          onPressed: () {
            widget.onSubmitted?.call(widget.textEditingController.text);
          },
          icon: const Icon(Icons.search),
        ),
        ...widget.actions ?? [],
      ],
      bottom: widget.bottom,
      flexibleSpace: widget.flexibleSpace,
    );
  }
}

class _PreferredAppBarSize extends Size {
  _PreferredAppBarSize(this.toolbarHeight, this.bottomHeight) : super.fromHeight((toolbarHeight ?? kToolbarHeight) + (bottomHeight ?? 0));

  final double? toolbarHeight;
  final double? bottomHeight;
}
