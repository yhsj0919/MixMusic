class PluginAccount {
  String status;
  String message;
  dynamic id;
  String name;
  String? pic;
  bool? isVip;
  DateTime? vipEndTime;

  PluginAccount({
    required this.status,
    this.message = '',
    this.id,
    this.name = '',
    this.pic,
    this.isVip,
    this.vipEndTime,
  });

  factory PluginAccount.fromJson(Map<String, dynamic> json) => PluginAccount(
    status: json['status'] as String,
    message: json['message'] as String? ?? '',
    id: json['id'],
    name: json['name'] as String? ?? '',
    pic: json['pic'] as String?,
    isVip: json['isVip'] as bool?,
    vipEndTime: json['vipEndTime'] == null
        ? null
        : DateTime.parse(json['vipEndTime'] as String).toLocal(),
  );
}
