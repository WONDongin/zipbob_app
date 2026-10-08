// UserDeviceResponseDto를 Flutter 객체변경
class UserDeviceModel {
  // DB가 발급한 번호
  final int userDeviceId;
  // 앱에서 만든 UUID
  final String deviceId;
  final String? osType;
  final String? osVersion;
  final String? deviceModel;

  const UserDeviceModel({
    required this.userDeviceId,
    required this.deviceId,
    this.osType,
    this.osVersion,
    this.deviceModel,
  });

  factory UserDeviceModel.fromJson(Map<String, dynamic> json) {
    return UserDeviceModel(
      userDeviceId: (json['userDeviceId'] as num).toInt(),
      deviceId: json['deviceId'] as String,
      osType: json['osType'] as String?,
      osVersion: json['osVersion'] as String?,
      deviceModel: json['deviceModel'] as String?,
    );
  }
}
