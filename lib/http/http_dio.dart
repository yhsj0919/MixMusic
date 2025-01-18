import 'dart:async';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'token_interceptor.dart';

import 'cookie_storage.dart';
import 'error_interceptor.dart';

class HttpDio {
  ///超时时间
  static const int CONNECT_TIMEOUT = 30000;
  static const int RECEIVE_TIMEOUT = 60000;

  static final HttpDio _instance = HttpDio._internal();

  factory HttpDio() => _instance;

  Dio? _dio;
  final CancelToken _cancelToken = CancelToken();

  HttpDio._internal() {
    if (_dio == null) {
      // BaseOptions、Options、RequestOptions 都可以配置参数，优先级别依次递增，且可以根据优先级别覆盖参数
      BaseOptions options = BaseOptions(
          connectTimeout: const Duration(milliseconds: CONNECT_TIMEOUT),
          // 响应流上前后两次接受到数据的间隔，单位为毫秒。
          receiveTimeout: const Duration(milliseconds: RECEIVE_TIMEOUT),
          // Http请求头.
          headers: {});

      options.extra['withCredentials'] = true;

      _dio = Dio(options);

      // 添加拦截器
      if (kDebugMode == true) {
        //只在测试的时候添加
        // _dio?.interceptors.add(LogInterceptor(request: false, requestHeader: false, responseHeader: false, responseBody: true, requestBody: true));
      }
      _dio?.interceptors.add(ErrorInterceptor());
      _dio?.interceptors.add(TokenInterceptor());
    }
  }

  ///初始化公共属性
  ///
  /// [baseUrl] 地址前缀
  /// [connectTimeout] 连接超时赶时间
  /// [receiveTimeout] 接收超时赶时间
  /// [interceptors] 基础拦截器
  Future<void> init({required String baseUrl, int? connectTimeout, int? receiveTimeout, List<Interceptor>? interceptors}) async {
    _dio?.options.baseUrl = baseUrl;
    _dio?.options.connectTimeout = Duration(milliseconds: connectTimeout ?? CONNECT_TIMEOUT);
    _dio?.options.receiveTimeout = Duration(milliseconds: receiveTimeout ?? RECEIVE_TIMEOUT);

    if (interceptors != null && interceptors.isNotEmpty) {
      _dio?.interceptors.addAll(interceptors);
    }
  }

  Future<CookieManager> getCookieManager({String? storageName}) async {
    //本地管理cookie
    return CookieManager(PersistCookieJar(storage: CookieStorage(storageName)));
  }

  /// 设置headers
  void setHeaders(Map<String, dynamic> map) {
    _dio?.options.headers.addAll(map);
  }

  ///校验证书
  void verifyCert(bool verify) {
    if (!verify) {
      (_dio?.httpClientAdapter as IOHttpClientAdapter?)?. createHttpClient=(){
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          return true;
        };
        return client;
      };

    }

  }

/*
   * 取消请求
   *
   * 同一个cancel token 可以用于多个请求，当一个cancel token取消时，所有使用该cancel token的请求都会被取消。
   * 所以参数可选
   */
  void cancelRequests({CancelToken? token}) {
    token ?? _cancelToken.cancel("cancelled");
  }

  ///  get
  Future get(String path, {Map<String, dynamic>? params, Options? options, CancelToken? cancelToken, ProgressCallback? onReceiveProgress}) async {
    Options requestOptions = options ?? Options();
    var response = await _dio?.get(
      path,
      queryParameters: params,
      options: requestOptions,
      cancelToken: cancelToken ?? _cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
    return response?.data;
  }

  ///  post
  Future post(String path,
      {Map<String, dynamic>? params, data, Options? options, CancelToken? cancelToken, ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) async {
    Options requestOptions = options ?? Options();
    var response = await _dio?.post(
      path,
      data: data,
      queryParameters: params,
      options: requestOptions,
      cancelToken: cancelToken ?? _cancelToken,
      onReceiveProgress: onReceiveProgress,
      onSendProgress: onSendProgress,
    );
    return response?.data;
  }

  ///  put 操作
  Future put(String path,
      {data, Map<String, dynamic>? params, Options? options, CancelToken? cancelToken, ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) async {
    Options requestOptions = options ?? Options();
    var response = await _dio?.put(
      path,
      data: data,
      queryParameters: params,
      options: requestOptions,
      cancelToken: cancelToken ?? _cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return response?.data;
  }

  ///  patch
  Future patch(String path,
      {data, Map<String, dynamic>? params, Options? options, CancelToken? cancelToken, ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) async {
    Options requestOptions = options ?? Options();
    var response = await _dio?.patch(
      path,
      data: data,
      queryParameters: params,
      options: requestOptions,
      cancelToken: cancelToken ?? _cancelToken,
      onReceiveProgress: onReceiveProgress,
      onSendProgress: onSendProgress,
    );
    return response?.data;
  }

  ///  delete
  Future delete(String path, {data, Map<String, dynamic>? params, Options? options, CancelToken? cancelToken}) async {
    Options requestOptions = options ?? Options();

    var response = await _dio?.delete(
      path,
      data: data,
      queryParameters: params,
      options: requestOptions,
      cancelToken: cancelToken ?? _cancelToken,
    );
    return response?.data;
  }

  ///  post form 表单提交
  Future postForm(String path,
      {Map<String, dynamic>? params, Options? options, CancelToken? cancelToken, ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) async {
    Options requestOptions = options ?? Options();

    var response = await _dio?.post(
      path,
      data: FormData.fromMap(params ?? {}),
      options: requestOptions,
      cancelToken: cancelToken ?? _cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return response?.data;
  }

  ///  download 下载
  Future download(String path, savePath,
      {Map<String, dynamic>? params, data, bool deleteOnError = true, ProgressCallback? onReceiveProgress, Options? options, CancelToken? cancelToken}) async {
    Options requestOptions = options ?? Options();

    var response = await _dio?.download(
      path,
      savePath,
      data: data,
      queryParameters: params,
      deleteOnError: deleteOnError,
      onReceiveProgress: onReceiveProgress,
      options: requestOptions,
      cancelToken: cancelToken ?? _cancelToken,
    );
    return response?.data;
  }
}
