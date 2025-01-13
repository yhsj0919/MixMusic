import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:mix_music/entity/plugins_info.dart';
import 'package:path/path.dart';

import 'kwDES.dart';

import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart'as asApi;
import 'package:pointycastle/asymmetric/rsa.dart';
///获取所有插件
Future<List<PluginsInfo>> getSystemPlugins({required String rootDir}) async {
  var dir = Directory(rootDir);
  final plugins = <PluginsInfo>[];
  var list = <FileSystemEntity>[];
  try {
    list = dir.listSync();
  } catch (e) {
    debugPrint("插件目录不存在:$e");
  }

  for (final ext in list) {
    if (ext.path.endsWith(".js")) {
      if (kDebugMode) {
        print(basename(ext.path));
      }
      var file = File(ext.path);
      final content = await file.readAsString();

      var info = parseExtension(content);

      if (info?.name?.isNotEmpty == true) {
        info!.path = ext.path;
        plugins.add(info);
      }
    }
  }
  return plugins;
}

///解析插件
PluginsInfo? parseExtension(String extension) {
  RegExp regex = RegExp(r'==MixMusicPlugin==([\s\S]*?)==\/MixMusicPlugin==');
  Match? match = regex.firstMatch(extension);

  if (match != null) {
    var info = match.group(1)?.trim() ?? "";

    Map<String, dynamic> result = {};
    RegExp reg = RegExp(r'@(\w+)\s+(.*)');
    Iterable<RegExpMatch> matches = reg.allMatches(info);
    for (RegExpMatch match in matches) {
      result[match.group(1)!] = match.group(2);
    }

    if (result.isNotEmpty) {
      result["code"] = extension.replaceAll("\r", "");
    } else {
      return null;
    }

    return JsonMapper.deserialize<PluginsInfo>(json.encode(result));
  } else {
    return null;
  }
}

///js扩展
extension JavascriptRuntimeFetchExtension on JavascriptRuntime {
  ///启用axios
  Future<JavascriptRuntime> enableAxios() async {
    String data = await rootBundle.loadString("assets/axios.js");
    final evalFetchResult = evaluate(data);
    if (kDebugMode) {
      print('Axios 结果: $evalFetchResult');
    }
    return this;
  }

  ///启用BigInt
  Future<JavascriptRuntime> enableBigInt() async {
    String data = await rootBundle.loadString("assets/BigInteger.min.js");
    final evalFetchResult = evaluate(data);
    if (kDebugMode) {
      print('BigInt 结果: $evalFetchResult');
    }
    return this;
  }

  ///启用Base64
  Future<JavascriptRuntime> enableBase64() async {
    String data = await rootBundle.loadString("assets/base64-js.js");
    final evalFetchResult = evaluate(data);
    if (kDebugMode) {
      print('Base64 结果: $evalFetchResult');
    }
    return this;
  }

  ///启用FastXmlParser
  Future<JavascriptRuntime> enableFastXmlParser() async {
    String data = await rootBundle.loadString("assets/fxparser.min.js");
    final evalFetchResult = evaluate(data);
    if (kDebugMode) {
      print('FastXmlParser 结果: $evalFetchResult');
    }
    return this;
  }

  JavascriptRuntime enableKwEncrypt2() {
    String method = "encrypt2";
    evaluate("""
      async function $method() {
         return await sendMessage('$method', JSON.stringify([...arguments]));
      }
    """);
    onMessage('$method', (dynamic args) {
      var src = args[0];
      var key = args[1];
      return Base64Codec().encode(KwDES.encrypt2(utf8.encode(src), utf8.encode(key)));
    });
    return this;
  }

  JavascriptRuntime enableRsaEncrypt() {
    String method = "rsaEncrypt";
    evaluate("""
      async function $method() {
         return await sendMessage('$method', JSON.stringify([...arguments]));
      }
    """);
    onMessage('$method', (dynamic args) async {
      var data = args[0].toString();
      var key = args[1].toString();

      print(">>>>data>>>>" + data);
      print(">>>>key>>>>" + key);

      // // 公钥和私钥
      // final publicKey = parseKeyFromString<asApi.RSAPublicKey>(key);
      //
      // // 创建加密器
      // final encrypter = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey));
      //
      // // 加密
      // final encrypted = encrypter.encrypt(data);
      // print('Encrypted: ${encrypted.base64}');
      //
      // // return encrypted.bytes.hex.toLowerCase();


      asApi.RSAPublicKey pubKey = RSAKeyParser().parse(key) as asApi.RSAPublicKey;
      final rsa = RSAEngine();
      rsa.init(true, PublicKeyParameter<asApi.RSAPublicKey>(pubKey));
      final encrypted = rsa.process(Uint8List.fromList(utf8.encode(data)));
      return Encrypted(encrypted).base16;
    });
    return this;
  }

  JavascriptRuntime enableRsaDecrypt() {
    String method = "rsaDecrypt";
    evaluate("""
      async function $method() {
         return await sendMessage('$method', JSON.stringify([...arguments]));
      }
    """);
    onMessage('$method', (dynamic args) async {
      var data = args[0].toString();
      var key = args[1].toString();

      // 公钥和私钥
      final privateKey = parseKeyFromString<asApi.RSAPrivateKey>(key);

      // 创建加密器
      final encrypter = encrypt.Encrypter(encrypt.RSA(privateKey: privateKey));

      // 加密
      final encrypted = encrypter.decrypt(Encrypted.fromUtf8(data));
      print('Encrypted: ${encrypted}');

      return encrypted;
    });
    return this;
  }

  JavascriptRuntime enableAesEncrypt() {
    String method = "aesEncrypt";
    evaluate("""
      async function $method() {
         return await sendMessage('$method', JSON.stringify([...arguments]));
      }
    """);
    onMessage('$method', (dynamic args) async {
      var data = args[0].toString();
      var key = args[1].toString();
      var iv = args[2].toString();

      print(data);
      print(key);
      print(iv);

      final myKey = encrypt.Key.fromUtf8(key);
      final myIv = encrypt.IV.fromUtf8(iv);

      final encrypter = Encrypter(AES(myKey, mode: encrypt.AESMode.cbc));

      final encrypted = encrypter.encrypt(data, iv: myIv);

      print(encrypted.base16); // R4PxiU3h8YoIRqVowBXm36ZcCeNeZ4s1OvVBTfFlZRdmohQqOpPQqD1YecJeZMAop/hZ4OxqgC1WtwvX/hP9mw==

      return encrypted.base16;
    });
    return this;
  }

  JavascriptRuntime enableAesDecrypt() {
    String method = "aesDecrypt";
    evaluate("""
      async function $method() {
         return await sendMessage('$method', JSON.stringify([...arguments]));
      }
    """);
    onMessage('$method', (dynamic args) async {
      var data = args[0].toString();
      var key = args[1].toString();
      var iv = args[2].toString();

      // print(data);
      // print(key);
      // print(iv);

      final myKey = encrypt.Key.fromUtf8(key);
      final myIv = encrypt.IV.fromUtf8(iv);

      final encrypter = Encrypter(AES(myKey, mode: encrypt.AESMode.cbc, padding: "PKCS7"));
      final decrypted = encrypter.encrypt(data, iv: myIv);

      print(decrypted); // Lorem ipsum dolor sit amet, consectetur adipiscing elit

      return decrypted;
    });
    return this;
  }

  JavascriptRuntime enableMd5() {
    String method = "md5";
    evaluate("""
      async function $method() {
         return await sendMessage('$method', JSON.stringify([...arguments]));
      }
    """);
    onMessage('$method', (dynamic args) async {
      var data = args[0].toString();

// 将字符串转换为字节
      List<int> bytes = utf8.encode(data);

      // 使用 MD5 算法进行哈希处理
      var md5Hash = md5.convert(bytes);

      // 输出 MD5 哈希值
      print("MD5 Hash: ${md5Hash.toString()}");

      return md5Hash.toString();
    });
    return this;
  }

  ///启用sleep
  Future<JavascriptRuntime> enableSleep() async {
    String data = await rootBundle.loadString("assets/sleep.js");
    final evalFetchResult = evaluate(data);
    if (kDebugMode) {
      print('sleep 结果: $evalFetchResult');
    }
    return this;
  }

  /// 启用加密
  Future<JavascriptRuntime> enableCrypto() async {
    String data = await rootBundle.loadString("assets/crypto.js");
    final evalFetchResult = evaluate(data);
    if (kDebugMode) {
      print('crypto 结果: $evalFetchResult');
    }
    return this;
  }
}

T parseKeyFromString<T extends asApi.RSAAsymmetricKey>(String key) {
  final parser = RSAKeyParser();
  return parser.parse(key) as T;
}


///js扩展
extension MethodExtension on JavascriptRuntime {
  bool contains({required String key, String obj = "music"}) {
    var check = evaluate("'$key' in $obj").rawResult as bool;
    return check;
  }

  List<String> keys({required String obj}) {
    var check = evaluate("Object.keys($obj)").rawResult as List;

    return check.map((e) => "$e").toList();
  }
}
