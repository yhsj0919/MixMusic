

class PageEntity {
  bool? first;
  bool? last;
  int? page;
  int? size;
  int? number;
  int? totalPages;
  int? totalSize;

  PageEntity(this.first, this.last, this.page, this.size, this.number, this.totalPages, this.totalSize);

  PageEntity.fromJson(json) {
    if (json['first'] != null) {
      first = json['first'];
    }

    if (json['last'] != null) {
      last = json['last'];
    }

    if (json['page'] != null) {
      page = json['page']?.toInt();
    }
    if (json['size'] != null) {
      size = json['size']?.toInt();
    }
    if (json['number'] != null) {
      number = json['number']?.toInt();
    }
    if (json['totalPages'] != null) {
      totalPages = json['totalPages']?.toInt();
    }

    if (json['totalSize'] != null) {
      totalSize = json['totalSize']?.toInt();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> resp = <String, dynamic>{};
    resp['first'] = first;
    resp['last'] = last;
    resp['page'] = page;
    resp['size'] = size;
    resp['number'] = number;
    resp['totalPages'] = totalPages;
    resp['totalSize'] = totalSize;

    return resp;
  }

  @override
  String toString() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['first'] = first;
    map['last'] = last;
    map['page'] = page;
    map['size'] = size;
    map['number'] = number;
    map['totalPages'] = totalPages;
    map['totalSize'] = totalSize;

    return map.toString();
  }
}
