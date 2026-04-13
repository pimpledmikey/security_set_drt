import 'active_package_item.dart';

class PackageDashboardData {
  PackageDashboardData({
    required this.pendingItems,
    required this.deliveredTodayItems,
    required this.pendingReceipts,
    required this.pendingPieces,
    required this.deliveredReceipts,
    required this.deliveredPieces,
  });

  final List<ActivePackageItem> pendingItems;
  final List<ActivePackageItem> deliveredTodayItems;
  final int pendingReceipts;
  final int pendingPieces;
  final int deliveredReceipts;
  final int deliveredPieces;

  factory PackageDashboardData.empty() {
    return PackageDashboardData(
      pendingItems: const [],
      deliveredTodayItems: const [],
      pendingReceipts: 0,
      pendingPieces: 0,
      deliveredReceipts: 0,
      deliveredPieces: 0,
    );
  }

  factory PackageDashboardData.fromJson(Map<String, dynamic> json) {
    final counts = json['counts'] as Map<String, dynamic>? ?? const {};
    final pendingRaw = json['pending_items'] as List<dynamic>? ?? const [];
    final deliveredRaw =
        json['delivered_today_items'] as List<dynamic>? ?? const [];

    return PackageDashboardData(
      pendingItems: pendingRaw
          .whereType<Map<String, dynamic>>()
          .map(ActivePackageItem.fromJson)
          .toList(),
      deliveredTodayItems: deliveredRaw
          .whereType<Map<String, dynamic>>()
          .map(ActivePackageItem.fromJson)
          .toList(),
      pendingReceipts: (counts['pending_receipts'] as num?)?.toInt() ?? 0,
      pendingPieces: (counts['pending_pieces'] as num?)?.toInt() ?? 0,
      deliveredReceipts: (counts['delivered_receipts'] as num?)?.toInt() ?? 0,
      deliveredPieces: (counts['delivered_pieces'] as num?)?.toInt() ?? 0,
    );
  }
}
