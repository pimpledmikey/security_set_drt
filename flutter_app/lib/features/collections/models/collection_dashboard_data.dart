import 'active_collection_item.dart';

class CollectionDashboardData {
  CollectionDashboardData({
    required this.pendingItems,
    required this.deliveredTodayItems,
    required this.pendingReceipts,
    required this.deliveredReceipts,
  });

  final List<ActiveCollectionItem> pendingItems;
  final List<ActiveCollectionItem> deliveredTodayItems;
  final int pendingReceipts;
  final int deliveredReceipts;

  factory CollectionDashboardData.empty() {
    return CollectionDashboardData(
      pendingItems: const [],
      deliveredTodayItems: const [],
      pendingReceipts: 0,
      deliveredReceipts: 0,
    );
  }

  factory CollectionDashboardData.fromJson(Map<String, dynamic> json) {
    final counts = json['counts'] as Map<String, dynamic>? ?? const {};
    final pendingRaw = json['pending_items'] as List<dynamic>? ?? const [];
    final deliveredRaw =
        json['delivered_today_items'] as List<dynamic>? ?? const [];

    return CollectionDashboardData(
      pendingItems: pendingRaw
          .whereType<Map<String, dynamic>>()
          .map(ActiveCollectionItem.fromJson)
          .toList(),
      deliveredTodayItems: deliveredRaw
          .whereType<Map<String, dynamic>>()
          .map(ActiveCollectionItem.fromJson)
          .toList(),
      pendingReceipts: (counts['pending_receipts'] as num?)?.toInt() ?? 0,
      deliveredReceipts: (counts['delivered_receipts'] as num?)?.toInt() ?? 0,
    );
  }
}
