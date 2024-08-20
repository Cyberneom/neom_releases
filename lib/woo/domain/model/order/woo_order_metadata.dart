import 'package:freezed_annotation/freezed_annotation.dart';

part 'woo_order_metadata.g.dart';

@JsonSerializable()
class WooOrderMetaData {

  int id;
  String key;
  dynamic value;

  WooOrderMetaData({
    this.id = 0,
    this.key = '',
    this.value,
  });
  factory WooOrderMetaData.fromJson(Map<String, dynamic> json) =>
      _$WooOrderMetaDataFromJson(json);

  Map<String, dynamic> toJson() => _$WooOrderMetaDataToJson(this);

}
