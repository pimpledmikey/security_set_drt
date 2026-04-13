class BootstrapPayload {
  BootstrapPayload({
    required this.companyName,
    required this.appointmentsEnabled,
    required this.quickPurposes,
    required this.packageEmailEnabled,
    required this.packageWhatsappEnabled,
    required this.collectionEmailEnabled,
    required this.collectionWhatsappEnabled,
    required this.visitEmailEnabled,
    required this.visitWhatsappEnabled,
  });

  final String companyName;
  final bool appointmentsEnabled;
  final List<String> quickPurposes;
  final bool packageEmailEnabled;
  final bool packageWhatsappEnabled;
  final bool collectionEmailEnabled;
  final bool collectionWhatsappEnabled;
  final bool visitEmailEnabled;
  final bool visitWhatsappEnabled;

  factory BootstrapPayload.fromJson(Map<String, dynamic> json) {
    return BootstrapPayload(
      companyName: json['company_name'] as String? ?? 'Control Entradas DRT',
      appointmentsEnabled: json['appointments_enabled'] as bool? ?? false,
      quickPurposes: (json['quick_purposes'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      packageEmailEnabled: json['package_email_enabled'] as bool? ?? false,
      packageWhatsappEnabled:
          json['package_whatsapp_enabled'] as bool? ?? false,
      collectionEmailEnabled:
          json['collection_email_enabled'] as bool? ?? false,
      collectionWhatsappEnabled:
          json['collection_whatsapp_enabled'] as bool? ?? false,
      visitEmailEnabled: json['visit_email_enabled'] as bool? ?? false,
      visitWhatsappEnabled: json['visit_whatsapp_enabled'] as bool? ?? false,
    );
  }
}
