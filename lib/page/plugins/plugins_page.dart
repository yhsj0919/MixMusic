import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mix_music/api/mix_api.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:mix_music/page/api_controller.dart';

class PluginsPage extends StatefulWidget {
  const PluginsPage({super.key});

  @override
  State<PluginsPage> createState() => _PluginsPageState();
}

class _PluginsPageState extends State<PluginsPage> {
  ApiController api = Get.put(ApiController());
  String? result;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 3,
        title: const Text("扩展管理"),
      ),
      body: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              child: Text(result ?? ""),
            ),
          ),
          Obx(() => ListView.builder(
              shrinkWrap: true,
              itemCount: api.plugins.length,
              itemBuilder: (context, index) {
                var plugin = api.getPlugin(index);

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network("${plugin.icon}", width: 40, height: 40, fit: BoxFit.cover),
                  ),
                  title: Text("${plugin.name}"),
                  subtitle: Text("${plugin.method}"),
                  onTap: () {
                    test(plugin);
                  },
                );
              }))
        ],
      ),
    );
  }

  test(PluginsInfo plugin) async {
    (await MixApi.api(plugins: plugin)).invokeMethod(method: "searchMusic", params: ["周杰伦","0"]).then((value) {
      setState(() {
        result = value;
        debugPrint(value);
      });
    }).catchError((e) {
      print(e);
      debugPrint('>>>>>>>>>>>>>>>>>');
    });
  }
}
