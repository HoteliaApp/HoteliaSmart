import 'package:flutter/material.dart';
import 'package:hotel_smart_app/config/theme/app_theme.dart';
import 'package:hotel_smart_app/widgets/app_ui.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color _getColor(BuildContext context) {
    final s = AppStatusColors.of(context);
    switch (status.toLowerCase()) {
      case 'limpia':
      case 'available':
      case 'completado':
      case 'completed':
        return s.success;
      case 'sucia':
      case 'dirty':
      case 'pendiente':
      case 'pending':
        return s.warning;
      case 'en limpieza':
      case 'maintenance':
      case 'en proceso':
      case 'inprogress':
      case 'reservada':
      case 'reserved':
        return s.info;
      case 'ocupada':
      case 'occupied':
        return s.danger;
      case 'cancelado':
      case 'cancelled':
        return s.neutral;
      default:
        return s.neutral;
    }
  }

  String _getLabel() {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Limpia';
      case 'occupied':
        return 'Ocupada';
      case 'reserved':
        return 'Reservada';
      case 'dirty':
        return 'Sucia';
      case 'maintenance':
        return 'En Limpieza';
      case 'pending':
        return 'Pendiente';
      case 'inprogress':
        return 'En proceso';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPill(
      label: _getLabel(),
      color: _getColor(context),
      outlined: true,
      dense: true,
    );
  }
}
