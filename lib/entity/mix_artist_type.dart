import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class MixArtistType {
  String package;
  dynamic id;
  String? title;

  List<MixArtistType>? subType = const [];

  MixArtistType({
    required this.package,
    this.id,
    this.title,
    this.subType = const [],
  });
}
