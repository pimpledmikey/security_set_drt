import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_time_formatter.dart';
import '../data/visit_detail_service.dart';
import '../models/visit_detail.dart';

class VisitorDetailView extends StatefulWidget {
  const VisitorDetailView({
    super.key,
    required this.visitId,
    required this.initialDetail,
  });

  final int visitId;
  final VisitDetail initialDetail;

  @override
  State<VisitorDetailView> createState() => _VisitorDetailViewState();
}

class _VisitorDetailViewState extends State<VisitorDetailView> {
  late VisitDetail _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _detail = widget.initialDetail;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await context.read<VisitDetailService>().fetchDetail(
          widget.visitId,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      if (result.data != null) {
        _detail = result.data!;
      } else {
        _error = result.errorMessage ?? 'No se pudo cargar el detalle.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del visitante')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            if (_error != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _DetailHeader(detail: _detail),
            const SizedBox(height: 14),
            _DocumentPreview(
              base64Image: _detail.documentImageBase64,
              loading: _loading,
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _InfoRow(label: 'Anfitrion', value: _detail.hostName),
                    _InfoRow(
                      label: 'Cita',
                      value: _detail.hasAppointment ? 'Si' : 'No',
                    ),
                    _InfoRow(
                      label: 'Personas',
                      value: _detail.groupSize == 1
                          ? '1 persona'
                          : '${_detail.groupSize} personas',
                    ),
                    _InfoRow(label: 'Motivo', value: _detail.purpose),
                    _InfoRow(
                      label: 'Observaciones',
                      value: _detail.observations.isEmpty
                          ? 'Sin observaciones'
                          : _detail.observations,
                    ),
                    _InfoRow(
                      label: 'Entrada',
                      value: DateTimeFormatter.dateTime(_detail.enteredAt),
                    ),
                    _InfoRow(
                      label: 'Documento',
                      value: _detail.identifierLabel,
                    ),
                    _InfoRow(
                      label: 'Identificador',
                      value: _detail.identifierValue.isEmpty
                          ? 'No disponible'
                          : _detail.identifierValue,
                    ),
                    _InfoRow(
                      label: 'Nacimiento',
                      value: _detail.birthDate.isEmpty
                          ? 'No disponible'
                          : _detail.birthDate,
                    ),
                    _InfoRow(
                      label: 'Emisor',
                      value: _detail.issuer.isEmpty
                          ? 'No disponible'
                          : _detail.issuer,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
            if (_loading) ...[
              const SizedBox(height: 14),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.detail});

  final VisitDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.person_outline_rounded,
                color: theme.colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.fullName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Consulta la fotografia y los datos capturados del acceso.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.textSoft
                          : AppColors.midnight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.base64Image, required this.loading});

  final String base64Image;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget content;

    if (base64Image.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Image);
        content = Container(
          height: 252,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.04)
                : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.memory(
                bytes,
                width: double.infinity,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
        );
      } catch (_) {
        content = _DocumentFallback(loading: loading);
      }
    } else {
      content = _DocumentFallback(loading: loading);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Foto del documento',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: content),
          ],
        ),
      ),
    );
  }
}

class _DocumentFallback extends StatelessWidget {
  const _DocumentFallback({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 34,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            loading ? 'Cargando foto...' : 'No hay foto disponible',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.borderSoft),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? AppColors.textSoft
                    : AppColors.midnight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
