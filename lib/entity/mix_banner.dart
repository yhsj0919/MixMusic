
import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class MixBanner {
  String site;
  dynamic id;
  String? title;
  String? pic;
  dynamic type;

  MixBanner({required this.site, required this.id, this.title, this.pic, this.type});
}
