
import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class MixBanner {
  String package;
  dynamic id;
  String? title;
  String? pic;
  dynamic type;

  MixBanner({required this.package, required this.id, this.title, this.pic, this.type});
}
