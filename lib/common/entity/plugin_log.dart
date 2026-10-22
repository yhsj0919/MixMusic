class PluginLog {
  String pluginId;
  String level;
  String message;
  DateTime time;

  PluginLog({
    required this.pluginId,
    required this.level,
    required this.message,
    required this.time,
  });

  @override
  String toString() =>
      '${time.toIso8601String()} [$pluginId] [$level] $message';
}
