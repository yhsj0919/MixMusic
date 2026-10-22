import 'package:lemon_x/lemon_x.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingController extends LxController {
  SettingController({this.preferences});
  final SharedPreferences? preferences;
  late final darkMode = own((preferences?.getBool('darkMode') ?? false).obs);

  Future<void> setDarkMode(bool value) async {
    darkMode.value = value;
    await preferences?.setBool('darkMode', value);
  }
}
