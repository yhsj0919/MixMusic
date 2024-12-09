import 'package:dio/dio.dart';

class DownloadRequest {
  final String url;
  final String path;
  String? fileName;
  bool formatName = false;

  var cancelToken = CancelToken();
  var forceDownload = false;

  DownloadRequest({
    required this.url,
    required this.path,
    this.fileName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DownloadRequest && runtimeType == other.runtimeType && url == other.url && path == other.path && fileName == other.fileName;

  @override
  int get hashCode => url.hashCode ^ path.hashCode;
}
