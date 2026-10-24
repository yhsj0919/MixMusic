//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <audio_service_win/audio_service_win_plugin_c_api.h>
#include <lemon_audio/lemon_audio_plugin_c_api.h>
#include <lemon_js/lemon_js_plugin_c_api.h>
#include <mpv_audio_kit/mpv_audio_kit_plugin_c_api.h>
#include <url_launcher_windows/url_launcher_windows.h>
#include <webview_all_windows/webview_all_windows_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  AudioServiceWinPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AudioServiceWinPluginCApi"));
  LemonAudioPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("LemonAudioPluginCApi"));
  LemonJsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("LemonJsPluginCApi"));
  MpvAudioKitPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("MpvAudioKitPluginCApi"));
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
  WebviewAllWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WebviewAllWindowsPlugin"));
}
