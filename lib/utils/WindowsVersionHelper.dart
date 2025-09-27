import 'dart:ffi';
import 'package:ffi/ffi.dart';

/// RtlGetVersion 使用的结构体（等价于 RTL_OSVERSIONINFOW）
final class RTL_OSVERSIONINFOW extends Struct {
  @Uint32()
  external int dwOSVersionInfoSize;

  @Uint32()
  external int dwMajorVersion;

  @Uint32()
  external int dwMinorVersion;

  @Uint32()
  external int dwBuildNumber;

  @Uint32()
  external int dwPlatformId;

  // WCHAR szCSDVersion[128];
  @Array(128)
  external Array<Uint16> szCSDVersion;
}

typedef _RtlGetVersionC = Int32 Function(Pointer<RTL_OSVERSIONINFOW>);
typedef _RtlGetVersionDart = int Function(Pointer<RTL_OSVERSIONINFOW>);

enum WindowsVersion { unknown, windows7, windows8, windows81, windows10, windows11 }

class WindowsVersionHelper {
  static final DynamicLibrary _ntdll = DynamicLibrary.open('ntdll.dll');
  static final _RtlGetVersionDart _rtlGetVersion = _ntdll.lookupFunction<_RtlGetVersionC, _RtlGetVersionDart>('RtlGetVersion');

  static WindowsVersion detect() {
    final info = calloc<RTL_OSVERSIONINFOW>();
    info.ref.dwOSVersionInfoSize = sizeOf<RTL_OSVERSIONINFOW>();

    final status = _rtlGetVersion(info);
    if (status != 0) {
      calloc.free(info);
      return WindowsVersion.unknown;
    }

    final major = info.ref.dwMajorVersion;
    final minor = info.ref.dwMinorVersion;
    final build = info.ref.dwBuildNumber;
    calloc.free(info);

    // 判别
    if (major == 6 && minor == 1) return WindowsVersion.windows7;
    if (major == 6 && minor == 2) return WindowsVersion.windows8;
    if (major == 6 && minor == 3) return WindowsVersion.windows81;
    if (major == 10) {
      return (build >= 22000) ? WindowsVersion.windows11 : WindowsVersion.windows10;
    }
    return WindowsVersion.unknown;
  }

  static bool isWindows10OrGreater() {
    final v = detect();
    return v == WindowsVersion.windows10 || v == WindowsVersion.windows11;
  }

  static bool isWindows11() => detect() == WindowsVersion.windows11;

  static String versionString() {
    final info = calloc<RTL_OSVERSIONINFOW>();
    info.ref.dwOSVersionInfoSize = sizeOf<RTL_OSVERSIONINFOW>();
    final status = _rtlGetVersion(info);
    if (status != 0) {
      calloc.free(info);
      return 'Unknown';
    }
    final s =
        'Windows ${info.ref.dwMajorVersion}'
        '.${info.ref.dwMinorVersion} (Build ${info.ref.dwBuildNumber})';
    calloc.free(info);
    return s;
  }
}

void main() {
  final v = WindowsVersionHelper.detect();
  print('当前系统版本: $v');
  print('详细: ${WindowsVersionHelper.versionString()}');
  print('>= Win10: ${WindowsVersionHelper.isWindows10OrGreater()}');
  print('Win11: ${WindowsVersionHelper.isWindows11()}');
}
