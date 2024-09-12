import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/constant.dart';
import 'package:mix_music/page/api_controller.dart';
import 'package:mix_music/utils/sp.dart';

class CookiePage extends StatefulWidget {
  const CookiePage({super.key});

  @override
  State<CookiePage> createState() => _CookiePageState();
}

class _CookiePageState extends State<CookiePage> {
  ApiController api = Get.put(ApiController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("cookie设置"),
        ),
        body: ListView.builder(
            itemCount: api.plugins.length,
            itemBuilder: (context, index) {
              var plugin = api.getPlugin(index);
              var cookie = Sp.getString("${Constant.KEY_COOKIE}_${plugin.package }");

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.network("${plugin.icon}", width: 40, height: 40, fit: BoxFit.cover),
                ),
                title: Text("${plugin.name}"),
                subtitle: Text(cookie?.isNotEmpty == true ? "$cookie" : "未设置"),
                onTap: () {
                  var controller = TextEditingController();

                  Get.defaultDialog(
                      title: "设置",
                      content: TextField(
                        maxLines: 5,
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: "请输入cookie",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      cancel: TextButton(
                          onPressed: () {
                            Get.back();
                          },
                          child: const Text("取消")),
                      confirm: TextButton(
                          onPressed: () {
                            print(controller.text);
                            Sp.setString("${Constant.KEY_COOKIE}_${plugin.package }", controller.text);
                            Get.back();
                            setState(() {});
                          },
                          child: const Text("确定")));
                },
              );
            }));
  }
}
