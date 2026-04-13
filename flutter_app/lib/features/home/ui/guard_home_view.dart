import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../../../core/utils/camera_selector.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/empty_state_card.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/primary_camera_button.dart';
import '../../../shared/widgets/runway_logo_lottie.dart';
import '../../collections/data/collection_active_service.dart';
import '../../collections/data/collection_deliver_service.dart';
import '../../collections/data/collection_receive_service.dart';
import '../../collections/models/active_collection_item.dart';
import '../../collections/models/collection_dashboard_data.dart';
import '../../collections/models/collection_deliver_request.dart';
import '../../collections/models/collection_receive_request.dart';
import '../../collections/ui/collection_delivery_sheet.dart';
import '../../collections/ui/collection_detail_view.dart';
import '../../collections/ui/collection_receive_view.dart';
import '../../collections/ui/widgets/active_collection_card.dart';
import '../../collections/ui/widgets/collection_summary_strip.dart';
import '../../packages/data/package_active_service.dart';
import '../../packages/data/package_deliver_service.dart';
import '../../packages/data/package_receive_service.dart';
import '../../packages/models/active_package_item.dart';
import '../../packages/models/package_dashboard_data.dart';
import '../../packages/models/package_deliver_request.dart';
import '../../packages/models/package_receive_request.dart';
import '../../packages/ui/package_delivery_sheet.dart';
import '../../packages/ui/package_detail_view.dart';
import '../../packages/ui/package_receive_view.dart';
import '../../packages/ui/widgets/active_package_card.dart';
import '../../packages/ui/widgets/package_summary_strip.dart';
import '../../scan/models/extract_result.dart';
import '../../scan/ui/scan_capture_view.dart';
import '../../scan/ui/scan_review_sheet.dart';
import '../../settings/ui/settings_view.dart';
import '../../visits/data/checkin_service.dart';
import '../../visits/data/checkout_service.dart';
import '../../visits/models/checkin_request.dart';
import '../../visits/models/visit_detail.dart';
import '../../visits/ui/visitor_detail_view.dart';
import '../data/active_visits_service.dart';
import '../models/active_visit_item.dart';
import 'widgets/active_visit_card.dart';
import 'widgets/home_summary_strip.dart';

class GuardHomeView extends StatefulWidget {
  const GuardHomeView({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<GuardHomeView> createState() => _GuardHomeViewState();
}

class _GuardHomeViewState extends State<GuardHomeView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<ActiveVisitItem> _activeVisits = const [];
  PackageDashboardData _packageDashboard = PackageDashboardData.empty();
  CollectionDashboardData _collectionDashboard =
      CollectionDashboardData.empty();
  bool _visitsLoading = true;
  bool _packagesLoading = true;
  bool _collectionsLoading = true;
  bool _saving = false;
  String _savingMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (mounted && !_tabController.indexIsChanging) {
          setState(() {});
        }
      });
    _loadVisits();
    _loadPackages();
    _loadCollections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVisits({
    bool showErrors = true,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      setState(() => _visitsLoading = true);
    }
    final result =
        await context.read<ActiveVisitsService>().fetchActiveVisits();
    if (!mounted) {
      return;
    }
    setState(() {
      _visitsLoading = false;
      if (result.data != null) {
        _activeVisits = result.data!;
      }
    });
    if (showErrors && !result.isSuccess && result.errorMessage != null) {
      showAppFeedback(
        context,
        result.errorMessage!,
        tone: AppFeedbackTone.error,
      );
    }
  }

  Future<void> _loadPackages({
    bool showErrors = true,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      setState(() => _packagesLoading = true);
    }
    final result = await context.read<PackageActiveService>().fetchDashboard();
    if (!mounted) {
      return;
    }
    setState(() {
      _packagesLoading = false;
      if (result.data != null) {
        _packageDashboard = result.data!;
      }
    });
    if (showErrors && !result.isSuccess && result.errorMessage != null) {
      showAppFeedback(
        context,
        result.errorMessage!,
        tone: AppFeedbackTone.error,
      );
    }
  }

  Future<void> _loadCollections({
    bool showErrors = true,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      setState(() => _collectionsLoading = true);
    }
    final result =
        await context.read<CollectionActiveService>().fetchDashboard();
    if (!mounted) {
      return;
    }
    setState(() {
      _collectionsLoading = false;
      if (result.data != null) {
        _collectionDashboard = result.data!;
      }
    });
    if (showErrors && !result.isSuccess && result.errorMessage != null) {
      showAppFeedback(
        context,
        result.errorMessage!,
        tone: AppFeedbackTone.error,
      );
    }
  }

  Future<PackageDashboardData?> _refreshPackagesSnapshot() async {
    final result = await context.read<PackageActiveService>().fetchDashboard();
    if (!mounted || result.data == null) {
      return null;
    }

    setState(() {
      _packagesLoading = false;
      _packageDashboard = result.data!;
    });
    return result.data;
  }

  Future<CollectionDashboardData?> _refreshCollectionsSnapshot() async {
    final result =
        await context.read<CollectionActiveService>().fetchDashboard();
    if (!mounted || result.data == null) {
      return null;
    }

    setState(() {
      _collectionsLoading = false;
      _collectionDashboard = result.data!;
    });
    return result.data;
  }

  bool _sameTrackingNumber(String left, String right) {
    return left.trim().toUpperCase() == right.trim().toUpperCase();
  }

  Future<void> _openScan() async {
    final preferredCamera = selectPreferredCamera(widget.cameras);
    if (preferredCamera == null) {
      showAppFeedback(
        context,
        'No se detectó cámara en este dispositivo.',
        tone: AppFeedbackTone.warning,
      );
      return;
    }

    final extract = await Navigator.of(context).push<ExtractResult>(
      MaterialPageRoute(
        builder: (_) => ScanCaptureView(camera: preferredCamera),
      ),
    );

    if (!mounted || extract == null) {
      return;
    }

    final request = await showModalBottomSheet<CheckInRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => ScanReviewSheet(initialResult: extract),
    );

    if (request == null || !mounted) {
      return;
    }

    setState(() {
      _saving = true;
      _savingMessage = 'Registrando visita...';
    });
    final result = await context.read<CheckInService>().checkIn(request);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (result.data != null) {
      setState(() {
        _activeVisits = [result.data!, ..._activeVisits];
      });
      showAppFeedback(
        context,
        'Visita registrada correctamente.',
        tone: AppFeedbackTone.info,
      );
      return;
    }
    showAppFeedback(
      context,
      result.errorMessage ?? 'No se pudo registrar la entrada.',
      tone: AppFeedbackTone.error,
    );
  }

  Future<void> _openPackageReceive() async {
    final request = await Navigator.of(context).push<PackageReceiveRequest>(
      MaterialPageRoute(
        builder: (_) => PackageReceiveView(cameras: widget.cameras),
      ),
    );

    if (request == null || !mounted) {
      return;
    }

    setState(() {
      _saving = true;
      _savingMessage = 'Registrando paquete...';
    });
    final result = await context.read<PackageReceiveService>().receive(request);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);

    if (result.data != null) {
      final response = result.data!;
      final newItem = response.package;
      setState(() {
        _packageDashboard = PackageDashboardData(
          pendingItems: [newItem, ..._packageDashboard.pendingItems],
          deliveredTodayItems: _packageDashboard.deliveredTodayItems,
          pendingReceipts: _packageDashboard.pendingReceipts + 1,
          pendingPieces: _packageDashboard.pendingPieces + newItem.packageCount,
          deliveredReceipts: _packageDashboard.deliveredReceipts,
          deliveredPieces: _packageDashboard.deliveredPieces,
        );
      });
      final message = response.notificationMessage.trim().isNotEmpty
          ? response.notificationMessage
          : 'Paquete registrado correctamente.';
      showAppFeedback(
        context,
        message,
        tone: AppFeedbackTone.package,
      );
      unawaited(_loadPackages(showErrors: false, showLoading: false));
      return;
    }

    final refreshedDashboard = await _refreshPackagesSnapshot();
    if (!mounted) {
      return;
    }
    if (refreshedDashboard != null) {
      final recoveredItem =
          refreshedDashboard.pendingItems.cast<ActivePackageItem?>().firstWhere(
                (package) =>
                    package != null &&
                    _sameTrackingNumber(
                        package.trackingNumber, request.trackingNumber),
                orElse: () => null,
              );
      if (recoveredItem != null) {
        showAppFeedback(
          context,
          'El paquete sí se registró. El servidor tardó demasiado en responder.',
          tone: AppFeedbackTone.package,
        );
        return;
      }
    }

    showAppFeedback(
      context,
      result.errorMessage ?? 'No se pudo registrar el paquete.',
      tone: AppFeedbackTone.error,
    );
  }

  Future<void> _openCollectionReceive() async {
    final request = await Navigator.of(context).push<CollectionReceiveRequest>(
      MaterialPageRoute(
        builder: (_) => CollectionReceiveView(cameras: widget.cameras),
      ),
    );

    if (request == null || !mounted) {
      return;
    }

    setState(() {
      _saving = true;
      _savingMessage = 'Registrando recoleccion...';
    });
    final result =
        await context.read<CollectionReceiveService>().receive(request);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);

    if (result.isSuccess) {
      if (result.data != null) {
        final newItem = result.data!;
        setState(() {
          _collectionDashboard = CollectionDashboardData(
            pendingItems: [newItem, ..._collectionDashboard.pendingItems],
            deliveredTodayItems: _collectionDashboard.deliveredTodayItems,
            pendingReceipts: _collectionDashboard.pendingReceipts + 1,
            deliveredReceipts: _collectionDashboard.deliveredReceipts,
          );
        });
      }
      showAppFeedback(
        context,
        'Recolección registrada correctamente.',
        tone: AppFeedbackTone.collection,
      );
      unawaited(_loadCollections(showErrors: false, showLoading: false));
      return;
    }

    final refreshedDashboard = await _refreshCollectionsSnapshot();
    if (!mounted) {
      return;
    }
    if (refreshedDashboard != null) {
      final recoveredItem = refreshedDashboard.pendingItems
          .cast<ActiveCollectionItem?>()
          .firstWhere(
            (collection) =>
                collection != null &&
                _sameTrackingNumber(
                  collection.trackingNumber,
                  request.trackingNumber,
                ),
            orElse: () => null,
          );
      if (recoveredItem != null) {
        showAppFeedback(
          context,
          'La recolección sí se registró. El servidor tardó demasiado en responder.',
          tone: AppFeedbackTone.collection,
        );
        return;
      }
    }

    showAppFeedback(
      context,
      result.errorMessage ?? 'No se pudo registrar la recolección.',
      tone: AppFeedbackTone.error,
    );
  }

  Future<void> _checkout(ActiveVisitItem item) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registrar salida'),
        content: Text('Se marcara la salida de ${item.fullName}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (approved != true || !mounted) {
      return;
    }

    setState(() {
      _saving = true;
      _savingMessage = 'Registrando salida...';
    });
    final result = await context.read<CheckOutService>().checkOut(item.id);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (result.isSuccess) {
      setState(() {
        _activeVisits =
            _activeVisits.where((visit) => visit.id != item.id).toList();
      });
      showAppFeedback(
        context,
        'Salida registrada para ${item.fullName}.',
        tone: AppFeedbackTone.success,
      );
      return;
    }
    showAppFeedback(
      context,
      result.errorMessage ?? 'No se pudo registrar la salida.',
      tone: AppFeedbackTone.error,
    );
  }

  Future<void> _deliverPackage(ActivePackageItem item) async {
    final request = await showModalBottomSheet<PackageDeliverRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => PackageDeliverySheet(
        packageId: item.id,
        recipientName: item.recipientName,
      ),
    );

    if (request == null || !mounted) {
      return;
    }

    setState(() {
      _saving = true;
      _savingMessage = 'Entregando paquete...';
    });
    final result = await context.read<PackageDeliverService>().deliver(request);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);

    if (result.isSuccess) {
      final deliveredItem = ActivePackageItem(
        id: item.id,
        recipientName: item.recipientName,
        recipientEmail: item.recipientEmail,
        recipientPhone: item.recipientPhone,
        hostName: item.hostName,
        guardReceivedName: item.guardReceivedName,
        trackingNumber: item.trackingNumber,
        carrierCompany: item.carrierCompany,
        packageCount: item.packageCount,
        notes: item.notes,
        status: 'DELIVERED',
        photoCount: item.photoCount,
        receivedAt: item.receivedAt,
        notifiedAt: item.notifiedAt,
        deliveredAt: DateTime.now(),
      );
      setState(() {
        _packageDashboard = PackageDashboardData(
          pendingItems: _packageDashboard.pendingItems
              .where((package) => package.id != item.id)
              .toList(),
          deliveredTodayItems: [
            deliveredItem,
            ..._packageDashboard.deliveredTodayItems,
          ],
          pendingReceipts:
              (_packageDashboard.pendingReceipts - 1).clamp(0, 9999).toInt(),
          pendingPieces: (_packageDashboard.pendingPieces - item.packageCount)
              .clamp(0, 9999)
              .toInt(),
          deliveredReceipts: _packageDashboard.deliveredReceipts + 1,
          deliveredPieces:
              _packageDashboard.deliveredPieces + item.packageCount,
        );
      });
      showAppFeedback(
        context,
        result.data ?? 'Entrega registrada para ${item.recipientName}.',
        tone: AppFeedbackTone.success,
      );
      unawaited(_loadPackages(showErrors: false, showLoading: false));
      return;
    }

    final refreshedDashboard = await _refreshPackagesSnapshot();
    if (!mounted) {
      return;
    }
    if (refreshedDashboard != null) {
      final stillPending = refreshedDashboard.pendingItems.any(
        (package) => package.id == item.id,
      );
      if (!stillPending) {
        showAppFeedback(
          context,
          'La entrega del paquete sí quedó registrada.',
          tone: AppFeedbackTone.success,
        );
        return;
      }
    }

    showAppFeedback(
      context,
      result.errorMessage ?? 'No se pudo entregar el paquete.',
      tone: AppFeedbackTone.error,
    );
  }

  Future<void> _deliverCollection(ActiveCollectionItem item) async {
    final request = await showModalBottomSheet<CollectionDeliverRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => CollectionDeliverySheet(
        collectionId: item.id,
        requesterName: item.requesterName,
      ),
    );

    if (request == null || !mounted) {
      return;
    }

    setState(() {
      _saving = true;
      _savingMessage = 'Entregando recoleccion...';
    });
    final result =
        await context.read<CollectionDeliverService>().deliver(request);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);

    if (result.isSuccess) {
      final deliveredItem = ActiveCollectionItem(
        id: item.id,
        requesterName: item.requesterName,
        requesterEmail: item.requesterEmail,
        requesterPhone: item.requesterPhone,
        hostName: item.hostName,
        guardHandoverName: item.guardHandoverName,
        trackingNumber: item.trackingNumber,
        carrierCompany: item.carrierCompany,
        notes: item.notes,
        status: 'DELIVERED',
        photoCount: item.photoCount,
        registeredAt: item.registeredAt,
        deliveredAt: DateTime.now(),
      );
      setState(() {
        _collectionDashboard = CollectionDashboardData(
          pendingItems: _collectionDashboard.pendingItems
              .where((collection) => collection.id != item.id)
              .toList(),
          deliveredTodayItems: [
            deliveredItem,
            ..._collectionDashboard.deliveredTodayItems,
          ],
          pendingReceipts:
              (_collectionDashboard.pendingReceipts - 1).clamp(0, 9999).toInt(),
          deliveredReceipts: _collectionDashboard.deliveredReceipts + 1,
        );
      });
      showAppFeedback(
        context,
        result.data ?? 'Entrega de recolección registrada correctamente.',
        tone: AppFeedbackTone.success,
      );
      unawaited(_loadCollections(showErrors: false, showLoading: false));
      return;
    }

    final refreshedDashboard = await _refreshCollectionsSnapshot();
    if (!mounted) {
      return;
    }
    if (refreshedDashboard != null) {
      final stillPending = refreshedDashboard.pendingItems.any(
        (collection) => collection.id == item.id,
      );
      if (!stillPending) {
        showAppFeedback(
          context,
          'La entrega de la recolección sí quedó registrada.',
          tone: AppFeedbackTone.success,
        );
        return;
      }
    }

    showAppFeedback(
      context,
      result.errorMessage ?? 'No se pudo entregar la recolección.',
      tone: AppFeedbackTone.error,
    );
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsView()));
  }

  void _openVisitDetail(ActiveVisitItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisitorDetailView(
          visitId: item.id,
          initialDetail: VisitDetail.fromActiveVisit(item),
        ),
      ),
    );
  }

  Future<void> _openPackageDetail(ActivePackageItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PackageDetailView(packageId: item.id),
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadPackages();
  }

  Future<void> _openCollectionDetail(ActiveCollectionItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CollectionDetailView(collectionId: item.id),
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadCollections();
  }

  String _latestEntryLabel() {
    if (_activeVisits.isEmpty) {
      return '--:--';
    }
    return DateTimeFormatter.shortTime(_activeVisits.first.enteredAt);
  }

  int _insidePeopleCount() {
    return _activeVisits.fold<int>(
      0,
      (total, visit) => total + (visit.groupSize <= 0 ? 1 : visit.groupSize),
    );
  }

  Widget _buildPrimaryAction() {
    if (_tabController.index == 1) {
      return PrimaryCameraButton(
        onPressed: _openPackageReceive,
        icon: Icons.inventory_2_outlined,
        label: 'Registrar paquete',
        backgroundColor: AppColors.packageAccent,
      );
    }

    if (_tabController.index == 2) {
      return PrimaryCameraButton(
        onPressed: _openCollectionReceive,
        icon: Icons.outbox_outlined,
        label: 'Registrar recoleccion',
        backgroundColor: AppColors.collectionAccent,
      );
    }

    return PrimaryCameraButton(onPressed: _openScan);
  }

  Widget _buildVisitsTab(BuildContext context) {
    final isDark = context.watch<ThemeController>().themeMode == ThemeMode.dark;
    return RefreshIndicator(
      onRefresh: () => _loadVisits(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          HomeSummaryStrip(
            insidePeopleCount: _insidePeopleCount(),
            activeVisitCount: _activeVisits.length,
            latestEntryLabel: _latestEntryLabel(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Personas dentro',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              Text(
                _activeVisits.length == 1
                    ? '1 visita activa'
                    : '${_activeVisits.length} visitas activas',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.textSoft : AppColors.midnight,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_visitsLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_activeVisits.isEmpty)
            const EmptyStateCard(
              title: 'No hay visitantes dentro',
              subtitle: 'Cuando registres una entrada aparecera aqui.',
            )
          else
            ..._activeVisits.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActiveVisitCard(
                  item: item,
                  onTap: () => _openVisitDetail(item),
                  onCheckout: () => _checkout(item),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPackagesTab(BuildContext context) {
    final theme = Theme.of(context);
    final pendingItems = _packageDashboard.pendingItems;
    final deliveredItems = _packageDashboard.deliveredTodayItems;

    return RefreshIndicator(
      onRefresh: () => _loadPackages(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          PackageSummaryStrip(
            pendingReceipts: _packageDashboard.pendingReceipts,
            pendingPieces: _packageDashboard.pendingPieces,
            deliveredReceipts: _packageDashboard.deliveredReceipts,
            deliveredPieces: _packageDashboard.deliveredPieces,
          ),
          const SizedBox(height: 18),
          if (_packagesLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Row(
              children: [
                Text(
                  'Pendientes de entregar',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  pendingItems.isEmpty
                      ? 'Sin pendientes'
                      : '${pendingItems.length} recepciones',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.textSoft
                        : AppColors.midnight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (pendingItems.isEmpty)
              const EmptyStateCard(
                title: 'No hay paquetes pendientes',
                subtitle:
                    'Los paquetes nuevos apareceran aqui hasta que se entreguen.',
              )
            else
              ...pendingItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ActivePackageCard(
                    item: item,
                    onTap: () => _openPackageDetail(item),
                    onDeliver: () => _deliverPackage(item),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Entregados hoy',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  deliveredItems.isEmpty
                      ? 'Sin entregas'
                      : '${deliveredItems.length} recepciones',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.textSoft
                        : AppColors.midnight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (deliveredItems.isEmpty)
              const EmptyStateCard(
                title: 'Aun no hay entregas hoy',
                subtitle:
                    'Cuando un paquete se cierre con firma aparecera aqui.',
              )
            else
              ...deliveredItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ActivePackageCard(
                    item: item,
                    onTap: () => _openPackageDetail(item),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollectionsTab(BuildContext context) {
    final theme = Theme.of(context);
    final pendingItems = _collectionDashboard.pendingItems;
    final deliveredItems = _collectionDashboard.deliveredTodayItems;

    return RefreshIndicator(
      onRefresh: () => _loadCollections(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          CollectionSummaryStrip(
            pendingReceipts: _collectionDashboard.pendingReceipts,
            deliveredReceipts: _collectionDashboard.deliveredReceipts,
          ),
          const SizedBox(height: 18),
          if (_collectionsLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Row(
              children: [
                Text(
                  'Pendientes de entregar',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  pendingItems.isEmpty
                      ? 'Sin pendientes'
                      : '${pendingItems.length} recolecciones',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.textSoft
                        : AppColors.midnight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (pendingItems.isEmpty)
              const EmptyStateCard(
                title: 'No hay recolecciones pendientes',
                subtitle:
                    'Las solicitudes nuevas apareceran aqui hasta que se entreguen al recolector.',
              )
            else
              ...pendingItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ActiveCollectionCard(
                    item: item,
                    onTap: () => _openCollectionDetail(item),
                    onDeliver: () => _deliverCollection(item),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Entregados hoy',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  deliveredItems.isEmpty
                      ? 'Sin entregas'
                      : '${deliveredItems.length} recolecciones',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.textSoft
                        : AppColors.midnight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (deliveredItems.isEmpty)
              const EmptyStateCard(
                title: 'Aun no hay recolecciones entregadas hoy',
                subtitle:
                    'Cuando una recoleccion se cierre con firma aparecera aqui.',
              )
            else
              ...deliveredItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ActiveCollectionCard(
                    item: item,
                    onTap: () => _openCollectionDetail(item),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeController>().themeMode == ThemeMode.dark;
    return LoadingOverlay(
      loading: _saving,
      title: _savingMessage,
      subtitle: 'La notificacion se enviara automaticamente.',
      child: Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        titleSpacing: 18,
        title: Row(
          children: [
            AppLogo(width: 60, height: 60),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Control Entradas DRT',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    'Accesos, paquetería y recolección',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              isDark ? AppColors.textSoft : AppColors.midnight,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.read<ThemeController>().toggle(),
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: _buildPrimaryAction(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.lightCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.borderSoft,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  splashBorderRadius: BorderRadius.circular(18),
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor:
                      isDark ? AppColors.textSoft : AppColors.midnight,
                  labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  unselectedLabelStyle:
                      Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Theme.of(
                      context,
                    )
                        .colorScheme
                        .primary
                        .withValues(alpha: isDark ? 0.24 : 0.14),
                  ),
                  tabs: const [
                    SizedBox(
                      height: 54,
                      child: Tab(
                        icon: Icon(Icons.badge_outlined),
                        text: 'Visitas',
                      ),
                    ),
                    SizedBox(
                      height: 54,
                      child: Tab(
                        icon: Icon(Icons.inventory_2_outlined),
                        text: 'Paquetes',
                      ),
                    ),
                    SizedBox(
                      height: 54,
                      child: Tab(
                        icon: Icon(Icons.outbox_outlined),
                        text: 'Recoleccion',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildVisitsTab(context),
                _buildPackagesTab(context),
                _buildCollectionsTab(context),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
