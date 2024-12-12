import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class MixMvType {
  String package;
  dynamic id;
  String? title;

  List<MixMvType>? subType = const [];

  MixMvType({
    required this.package,
    required this.id,
    required this.title,
    this.subType = const [],
  });
}
