import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/utils/debounce.dart';

class SliverSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  SliverSearchAppBar({
    super.key,
    required this.textEditingController,
    required this.optionsBuilder,
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
    this.focusNode,
  }) : preferredSize = _PreferredAppBarSize(toolbarHeight, bottom?.preferredSize.height);
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
  final AutocompleteOptionsBuilder<String> optionsBuilder;
  final debounce = Debounce<Iterable<String>>(delay: Duration(milliseconds: 800));
  final RxBool showProgress = RxBool(false);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      title: LayoutBuilder(
        builder: (context, constraints) {
          return RawAutocomplete<String>(
            focusNode: focusNode,
            textEditingController: textEditingController,
            optionsBuilder: (v) {
              showProgress.value = true;
              return debounce.run(() => optionsBuilder.call(v)).then((v) {
                showProgress.value = false;

                return v;
              });
            },
            onSelected: (String selection) {
              onSubmitted?.call(selection);
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  suffixIcon: Obx(() => showProgress.value
                      ? Container(
                          width: 10,
                          height: 10,
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : SizedBox(width: 0, height: 0)), // 右侧图标
                ),
                autofocus: false,
                onChanged: (value) {
                  onChanged?.call(value);
                },
                onSubmitted: (value) {
                  onFieldSubmitted();
                  onSubmitted?.call(value);
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Material(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0), // 圆角
                      ),
                      elevation: 4.0,
                      child: Container(
                        width: constraints.maxWidth, // 使下拉框宽度与输入框一致
                        constraints: const BoxConstraints(maxHeight: 500),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final String option = options.elementAt(index);
                            return ListTile(
                              title: Text(option),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    )),
              );
            },
          );
        },
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
