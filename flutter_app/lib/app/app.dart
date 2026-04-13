import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/api_client.dart';
import '../core/storage/session_store.dart';
import '../core/storage/theme_store.dart';
import '../features/bootstrap/data/bootstrap_service.dart';
import '../features/collections/data/collection_active_service.dart';
import '../features/collections/data/collection_deliver_service.dart';
import '../features/collections/data/collection_detail_service.dart';
import '../features/collections/data/collection_receive_service.dart';
import '../features/guards/data/guard_service.dart';
import '../features/home/data/active_visits_service.dart';
import '../features/hosts/data/host_service.dart';
import '../features/packages/data/package_active_service.dart';
import '../features/packages/data/package_carrier_service.dart';
import '../features/packages/data/package_deliver_service.dart';
import '../features/packages/data/package_detail_service.dart';
import '../features/packages/data/package_receive_service.dart';
import '../features/scan/data/ocr_service.dart';
import '../features/scan/data/scan_service.dart';
import '../features/settings/data/app_settings_service.dart';
import '../features/visits/data/checkin_service.dart';
import '../features/visits/data/checkout_service.dart';
import '../features/visits/data/visit_detail_service.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class RunwayAccessApp extends StatelessWidget {
  const RunwayAccessApp({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => SessionStore()),
        Provider(create: (_) => ThemeStore()),
        ChangeNotifierProvider(
          create: (context) =>
              ThemeController(context.read<ThemeStore>())..load(),
        ),
        ProxyProvider<SessionStore, ApiClient>(
          update: (_, sessionStore, __) =>
              ApiClient(sessionStore: sessionStore),
        ),
        ProxyProvider<ApiClient, BootstrapService>(
          update: (_, apiClient, __) => BootstrapService(apiClient),
        ),
        ProxyProvider<ApiClient, ActiveVisitsService>(
          update: (_, apiClient, __) => ActiveVisitsService(apiClient),
        ),
        ProxyProvider<ApiClient, HostService>(
          update: (_, apiClient, __) => HostService(apiClient),
        ),
        ProxyProvider<ApiClient, GuardService>(
          update: (_, apiClient, __) => GuardService(apiClient),
        ),
        ProxyProvider<ApiClient, PackageActiveService>(
          update: (_, apiClient, __) => PackageActiveService(apiClient),
        ),
        ProxyProvider<ApiClient, PackageCarrierService>(
          update: (_, apiClient, __) => PackageCarrierService(apiClient),
        ),
        ProxyProvider<ApiClient, PackageReceiveService>(
          update: (_, apiClient, __) => PackageReceiveService(apiClient),
        ),
        ProxyProvider<ApiClient, PackageDetailService>(
          update: (_, apiClient, __) => PackageDetailService(apiClient),
        ),
        ProxyProvider<ApiClient, PackageDeliverService>(
          update: (_, apiClient, __) => PackageDeliverService(apiClient),
        ),
        ProxyProvider<ApiClient, CollectionActiveService>(
          update: (_, apiClient, __) => CollectionActiveService(apiClient),
        ),
        ProxyProvider<ApiClient, CollectionReceiveService>(
          update: (_, apiClient, __) => CollectionReceiveService(apiClient),
        ),
        ProxyProvider<ApiClient, CollectionDetailService>(
          update: (_, apiClient, __) => CollectionDetailService(apiClient),
        ),
        ProxyProvider<ApiClient, CollectionDeliverService>(
          update: (_, apiClient, __) => CollectionDeliverService(apiClient),
        ),
        ProxyProvider<ApiClient, AppSettingsService>(
          update: (_, apiClient, __) => AppSettingsService(apiClient),
        ),
        Provider(
          create: (_) => OcrService(),
          dispose: (_, service) => service.dispose(),
        ),
        ProxyProvider2<ApiClient, OcrService, ScanService>(
          update: (_, apiClient, ocrService, __) =>
              ScanService(apiClient: apiClient, ocrService: ocrService),
        ),
        ProxyProvider<ApiClient, CheckInService>(
          update: (_, apiClient, __) => CheckInService(apiClient),
        ),
        ProxyProvider<ApiClient, CheckOutService>(
          update: (_, apiClient, __) => CheckOutService(apiClient),
        ),
        ProxyProvider<ApiClient, VisitDetailService>(
          update: (_, apiClient, __) => VisitDetailService(apiClient),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'Control Entradas DRT',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.midnightTheme,
            themeMode: themeController.themeMode,
            home: AppRouter(cameras: cameras),
          );
        },
      ),
    );
  }
}
