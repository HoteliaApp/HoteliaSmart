import 'package:flutter/material.dart';
import 'package:hotel_smart_app/config/theme/app_theme.dart';
import 'package:hotel_smart_app/widgets/app_ui.dart';
import '../models/task_model.dart';
import 'activity_row.dart';

class ActivityTable extends StatelessWidget {
  final List<TaskModel> tasks;

  const ActivityTable({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Servicio', style: headerStyle)),
                Expanded(flex: 2, child: Text('Encargado', style: headerStyle)),
                Expanded(flex: 1, child: Text('Habitación', style: headerStyle)),
                Expanded(flex: 2, child: Text('Fecha', style: headerStyle)),
                Expanded(flex: 2, child: Text('Estado', style: headerStyle)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: tasks.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ActivityRow(task: tasks[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
