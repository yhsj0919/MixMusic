import 'package:dio/dio.dart';
import 'package:mix_music/utils/sp.dart';

/// Token处理拦截器
class TokenInterceptor extends Interceptor {
  TokenInterceptor({this.tokenName = "Authorization"});

  String tokenName;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    var ss = options.uri.host;

    var token = Sp.getString(ss);

    if (token?.isNotEmpty == true) {
      options.headers[tokenName] = token;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _saveToken(response).then((_) => handler.next(response)).catchError((e, stackTrace) {
      var err = DioException(requestOptions: response.requestOptions, error: e, stackTrace: stackTrace);
      handler.reject(err, true);
    });
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      _saveToken(err.response!).then((_) => handler.next(err)).catchError((e, stackTrace) {
        var myError = DioException(requestOptions: err.response!.requestOptions, error: e, stackTrace: stackTrace);
        handler.next(myError);
      });
    } else {
      handler.next(err);
    }
  }

  Future<void> _saveToken(Response response) async {
    var token = response.headers[tokenName];

    if (token != null && token.isNotEmpty) {
      var ss = response.requestOptions.uri.host;
      await Sp.setString(ss, token.first);
    }
  }
}
