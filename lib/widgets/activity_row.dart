import 'package:flutter/material.dart';
import 'package:hotel_smart_app/config/theme/app_theme.dart';
import '../models/task_model.dart';
import 'status_badge.dart';

class ActivityRow extends StatefulWidget {
  final TaskModel task;

  const ActivityRow({super.key, required this.task});

  @override
  State<ActivityRow> createState() => _ActivityRowState();
}

class _ActivityRowState extends State<ActivityRow> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = AppStatusColors.of(context);

    return InkWell(
      onTap: () {},
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      child: Container(
        color: _isFocused
            ? AppColors.primary.withValues(alpha: AppAlpha.tint)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColors.info,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      widget.task.serviceType,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                widget.task.assignedTo,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                widget.task.room,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                widget.task.formattedDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(flex: 2, child: StatusBadge(status: widget.task.status)),
          ],
        ),
      ),
    );
  }
}
