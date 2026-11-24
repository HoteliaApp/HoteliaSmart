import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hotel_smart_app/config/theme/app_theme.dart';
import 'package:hotel_smart_app/widgets/app_ui.dart';
import '../models/task_model.dart';
import 'task_card.dart';

/// Columna del tablero Kanban para la Smart TV.
class KanbanColumn extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<TaskModel> tasks;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.tasks,
  });

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _checkAutoScroll();
  }

  @override
  void didUpdateWidget(covariant KanbanColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks.length != oldWidget.tasks.length) {
      _checkAutoScroll();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkAutoScroll() {
    if (widget.tasks.length > 3 && !_isScrolling) {
      _isScrolling = true;
      Future.delayed(const Duration(seconds: 2), _autoScrollLoop);
    } else if (widget.tasks.length <= 3) {
      _isScrolling = false;
    }
  }

  Future<void> _autoScrollLoop() async {
    while (_isScrolling && mounted) {
      if (!_scrollController.hasClients) {
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }

      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) {
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }

      await _scrollController.animateTo(
        maxScroll,
        duration: const Duration(seconds: 8),
        curve: Curves.linear,
      );

      if (!mounted || !_isScrolling) break;
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted || !_isScrolling) break;

      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
      );

      if (!mounted || !_isScrolling) break;
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accent: widget.color,
      radius: AppRadius.lg,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: widget.tasks.isEmpty
                ? const AppEmptyState(
                    icon: Icons.check_circle_rounded,
                    title: 'Sin tareas',
                  )
                : _buildTaskList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: AppAlpha.tint),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        border: Border(
          bottom: BorderSide(
            color: widget.color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          AppIconBadge(
            icon: widget.icon,
            color: widget.color,
            size: 36,
            iconSize: AppIconSize.sm,
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text(
              widget.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AppPill(label: '${widget.tasks.length}', color: widget.color),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: widget.tasks.length,
      itemBuilder: (context, index) {
        final task = widget.tasks[index];
        return TaskCard(
          serviceType: task.serviceType,
          assignedTo: task.assignedTo,
          room: task.room,
          timeLabel: task.formattedDate,
          status: task.status,
        );
      },
    );
  }
}
