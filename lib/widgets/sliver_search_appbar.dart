import 'package:flutter/material.dart';

class SliverSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  SliverSearchAppBar(
      {super.key,
      required this.textEditingController,
      this.actions,
      this.bottom,
      this.flexibleSpace,
      this.toolbarHeight,
      this.onSubmitted,
      this.onChanged,
      this.hintText,
      this.forceElevated = false,
      this.pinned = true,
      this.backgroundColor,
      this.focusNode})
      : preferredSize = _PreferredAppBarSize(toolbarHeight, bottom?.preferredSize.height);
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? flexibleSpace;
  final double? toolbarHeight;
  final TextEditingController textEditingController;
  final Function(String)? onSubmitted;
  final Function(String)? onChanged;
  final String? hintText;
  final bool forceElevated;
  final bool pinned;
  final Color? backgroundColor;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      title: TextField(
        controller: textEditingController,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
        ),
        autofocus: false,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
      actions: [
        IconButton(
          onPressed: () {
            onSubmitted?.call(textEditingController.text);
          },
          icon: const Icon(Icons.search),
        ),
        ...actions ?? [],
      ],
      bottom: bottom,
      forceElevated: forceElevated,
      pinned: pinned,
      flexibleSpace: flexibleSpace,
    );
  }

  @override
  final Size preferredSize;
}

class _PreferredAppBarSize extends Size {
  _PreferredAppBarSize(this.toolbarHeight, this.bottomHeight) : super.fromHeight((toolbarHeight ?? kToolbarHeight) + (bottomHeight ?? 0));

  final double? toolbarHeight;
  final double? bottomHeight;
}
