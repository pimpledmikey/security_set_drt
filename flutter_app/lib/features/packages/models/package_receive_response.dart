import 'active_package_item.dart';

class PackageReceiveResponse {
  PackageReceiveResponse({
    required this.package,
    required this.notificationAttempted,
    required this.notificationSent,
    required this.notificationMessage,
  });

  final ActivePackageItem package;
  final bool notificationAttempted;
  final bool notificationSent;
  final String notificationMessage;

  factory PackageReceiveResponse.fromJson(Map<String, dynamic> json) {
    final packageJson = json['package'] as Map<String, dynamic>? ?? const {};
    final notification =
        json['notification'] as Map<String, dynamic>? ?? const {};
    return PackageReceiveResponse(
      package: ActivePackageItem.fromJson(packageJson),
      notificationAttempted: notification['attempted'] as bool? ?? false,
      notificationSent: notification['sent'] as bool? ?? false,
      notificationMessage: notification['message'] as String? ?? '',
    );
  }
}
