import 'dart:convert';

enum CallState { connecting, active, held, ended }

class Call {
  String uuid;
  String address;
  bool outgoing;

  Call({
    required this.uuid,
    required this.address,
    required this.outgoing,
  });

  Call copyWith({
    String? uuid,
    String? address,
    bool? outgoing,
  }) {
    return Call(
      uuid: uuid ?? this.uuid,
      address: address ?? this.address,
      outgoing: outgoing ?? this.outgoing,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'address': address,
      'outgoing': outgoing,
    };
  }

  factory Call.fromMap(Map<String, dynamic> map) {
    return Call(
      uuid: map['uuid'],
      address: map['address'],
      outgoing: map['outgoing'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Call.fromJson(String source) => Call.fromMap(json.decode(source));

  @override
  String toString() =>
      'Call(uuid: $uuid, address: $address, outgoing: $outgoing)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Call &&
        other.uuid == uuid &&
        other.address == address &&
        other.outgoing == outgoing;
  }

  @override
  int get hashCode => uuid.hashCode ^ address.hashCode ^ outgoing.hashCode;
}
