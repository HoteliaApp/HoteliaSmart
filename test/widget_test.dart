import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_smart_app/main.dart';
import 'package:hotel_smart_app/models/notification_model.dart';
import 'package:hotel_smart_app/models/room_model.dart';
import 'package:hotel_smart_app/models/task_model.dart';
import 'package:hotel_smart_app/providers/notifications_provider.dart';
import 'package:hotel_smart_app/providers/rooms_provider.dart';
import 'package:hotel_smart_app/providers/tasks_provider.dart';
import 'package:hotel_smart_app/screens/home_screen.dart';
import 'package:hotel_smart_app/widgets/daily_metrics_view.dart';
import 'package:hotel_smart_app/widgets/floor_map_view.dart';
import 'package:hotel_smart_app/widgets/notification_banner.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HotelSmartApp()));
    expect(find.byType(HotelSmartApp), findsOneWidget);
  });

  group('NotificationModel.fromFirestore', () {
    test('mapea alerta activa con prioridad alta, cuarto, motivo y hotelId',
        () {
      final alert = NotificationModel.fromFirestore('alert-1', {
        'title': 'Habitación sucia por tiempo prolongado',
        'description': 'Más de 90 minutos sin limpieza',
        'roomNumber': 204,
        'priority': 'high',
        'type': 'dirty_room_timeout',
        'hotelId': 'hotel-01',
        'isAcknowledged': false,
        'createdAt': DateTime.now().toIso8601String(),
      });

      expect(alert.id, 'alert-1');
      expect(alert.isAcknowledged, isFalse);
      expect(alert.active, isTrue);
      expect(alert.isHighPriority, isTrue);
      expect(alert.relatedRoom, '204');
      expect(alert.roomLabel, 'Hab. 204');
      expect(alert.title, 'Habitación sucia por tiempo prolongado');
      expect(alert.description, 'Más de 90 minutos sin limpieza');
      expect(alert.hotelId, 'hotel-01');
    });

    test(
        'marca active == false cuando isAcknowledged == true y detecta baja prioridad',
        () {
      final alert = NotificationModel.fromFirestore('alert-2', {
        'title': 'Aviso menor',
        'description': 'Revisión rutinaria',
        'relatedRoom': '101',
        'priority': 'low',
        'isAcknowledged': true,
      });

      expect(alert.isAcknowledged, isTrue);
      expect(alert.active, isFalse);
      expect(alert.isHighPriority, isFalse);
    });

    test('asume prioridad alta si el documento no especifica priority', () {
      final alert = NotificationModel.fromFirestore('alert-3', {
        'title': 'Avería eléctrica',
        'room': '305',
        'isAcknowledged': false,
      });

      expect(alert.active, isTrue);
      expect(alert.isHighPriority, isTrue);
      expect(alert.roomLabel, 'Hab. 305');
    });
  });

  group('[H-23] Overlay de Alertas Críticas Ambientales', () {
    testWidgets(
        'NotificationBanner.show despliega el banner arriba durante 10 segundos con cuarto y motivo',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final alert = NotificationModel(
        id: 'alert-high-1',
        title: 'Avería de mantenimiento urgente',
        description: 'Fuga de agua en baño principal',
        relatedRoom: '402',
        createdAt: DateTime.now(),
        priority: 'high',
        isAcknowledged: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => NotificationBanner.show(context, alert),
                  child: const Text('Disparar alerta'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Disparar alerta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final bannerFinder = find.byType(NotificationBanner);
      expect(bannerFinder, findsOneWidget);
      expect(find.text('Hab. 402'), findsOneWidget);
      expect(find.text('Avería de mantenimiento urgente'), findsOneWidget);
      expect(find.text('Fuga de agua en baño principal'), findsOneWidget);

      final bannerTop = tester.getTopLeft(bannerFinder).dy;
      expect(bannerTop, lessThan(180));

      // A los 5 segundos el banner debe seguir visible.
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(NotificationBanner), findsOneWidget);

      // Al cumplirse los 10 segundos y terminar la animación de salida, desaparece.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationBanner), findsNothing);
    });

    testWidgets(
        'HomeScreen despliega el overlay de 10 segundos cuando recibe una alerta de prioridad alta en el stream',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final alertsController = StreamController<List<NotificationModel>>();
      addTearDown(alertsController.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomsStreamProvider.overrideWith(
              (ref) => Stream.value(const <RoomModel>[]),
            ),
            pendingTasksStreamProvider.overrideWith(
              (ref) => Stream.value(const <TaskModel>[]),
            ),
            inProgressTasksStreamProvider.overrideWith(
              (ref) => Stream.value(const <TaskModel>[]),
            ),
            completedTasksStreamProvider.overrideWith(
              (ref) => Stream.value(const <TaskModel>[]),
            ),
            notificationsProvider.overrideWith(
              (ref) => alertsController.stream,
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      alertsController.add([
        NotificationModel(
          id: 'alert-stream-1',
          title: 'Habitación demasiado tiempo sucia',
          description: 'Tiempo excedido en limpieza de salida',
          relatedRoom: '510',
          createdAt: DateTime.now(),
          priority: 'high',
          isAcknowledged: false,
        ),
      ]);

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(NotificationBanner), findsOneWidget);
      expect(find.text('Hab. 510'), findsWidgets);
      expect(
        find.text('Habitación demasiado tiempo sucia'),
        findsWidgets,
      );

      // Sigue visible a los 5 segundos.
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(NotificationBanner), findsOneWidget);

      // Desaparece tras completar los 10 segundos y la animación de salida.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(NotificationBanner), findsNothing);
    });
  });

  group('[H-33] Dashboard de Monitoreo General de Limpieza y Ocupación', () {
    test('DailyKpiMetrics calcula porcentaje de ocupación y tiempo medio de entrega del día',
        () {
      final now = DateTime(2026, 11, 20, 12, 0);
      final rooms = [
        const RoomModel(
          id: '101',
          numero: '101',
          piso: 1,
          tipo: RoomType.single,
          estado: RoomStatus.occupied,
        ),
        const RoomModel(
          id: '102',
          numero: '102',
          piso: 1,
          tipo: RoomType.double_,
          estado: RoomStatus.occupied,
        ),
        const RoomModel(
          id: '201',
          numero: '201',
          piso: 2,
          tipo: RoomType.suite,
          estado: RoomStatus.occupied,
        ),
        const RoomModel(
          id: '202',
          numero: '202',
          piso: 2,
          tipo: RoomType.deluxe,
          estado: RoomStatus.dirty,
        ),
      ];

      final completedTasks = [
        // 20 min hoy
        TaskModel(
          id: 't1',
          serviceType: 'cleaning',
          assignedTo: 'Ana',
          room: '101',
          status: 'completed',
          createdAt: DateTime(2026, 11, 20, 9, 0),
          startedAt: DateTime(2026, 11, 20, 9, 10),
          completedAt: DateTime(2026, 11, 20, 9, 30),
        ),
        // 30 min hoy
        TaskModel(
          id: 't2',
          serviceType: 'cleaning',
          assignedTo: 'Luis',
          room: '201',
          status: 'completed',
          createdAt: DateTime(2026, 11, 20, 10, 0),
          completedAt: DateTime(2026, 11, 20, 10, 30),
        ),
        // Tarea de ayer: no debe afectar el promedio del día
        TaskModel(
          id: 't-old',
          serviceType: 'cleaning',
          assignedTo: 'Luis',
          room: '102',
          status: 'completed',
          createdAt: DateTime(2026, 11, 19, 10, 0),
          completedAt: DateTime(2026, 11, 19, 12, 0),
        ),
      ];

      final metrics = DailyKpiMetrics.fromData(
        rooms: rooms,
        completedTasks: completedTasks,
        pendingTasksCount: 2,
        inProgressTasksCount: 1,
        now: now,
      );

      expect(metrics.occupancyPercentage, closeTo(75.0, 0.01));
      expect(metrics.occupancyLabel, '75.0%');
      expect(metrics.completedTodayCount, 2);
      expect(metrics.averageDeliveryMinutes, closeTo(25.0, 0.01));
      expect(metrics.averageDeliveryLabel, '25 min');
      expect(metrics.roomStats.dirty, 1);
      expect(metrics.pendingTasksCount, 2);
      expect(metrics.inProgressTasksCount, 1);
    });

    testWidgets(
        'Modo rotativo automático alterna entre Mapa de Pisos y Estadísticas del Día cada 60 segundos sin interacción',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final sampleRooms = [
        const RoomModel(
          id: '101',
          numero: '101',
          piso: 1,
          tipo: RoomType.single,
          estado: RoomStatus.occupied,
        ),
        const RoomModel(
          id: '102',
          numero: '102',
          piso: 1,
          tipo: RoomType.double_,
          estado: RoomStatus.occupied,
        ),
        const RoomModel(
          id: '201',
          numero: '201',
          piso: 2,
          tipo: RoomType.suite,
          estado: RoomStatus.occupied,
        ),
        const RoomModel(
          id: '202',
          numero: '202',
          piso: 2,
          tipo: RoomType.deluxe,
          estado: RoomStatus.dirty,
        ),
      ];

      final completedToday = [
        TaskModel(
          id: 'c1',
          serviceType: 'cleaning',
          assignedTo: 'Ana',
          room: '101',
          status: 'completed',
          createdAt: now.subtract(const Duration(minutes: 25)),
          completedAt: now,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomsStreamProvider.overrideWith((ref) => Stream.value(sampleRooms)),
            pendingTasksStreamProvider
                .overrideWith((ref) => Stream.value(const <TaskModel>[])),
            inProgressTasksStreamProvider
                .overrideWith((ref) => Stream.value(const <TaskModel>[])),
            completedTasksStreamProvider
                .overrideWith((ref) => Stream.value(completedToday)),
            notificationsProvider.overrideWith(
              (ref) => Stream.value(const <NotificationModel>[]),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      // Inicia en Mapa de Pisos en modo quiosco.
      expect(find.byType(FloorMapView), findsOneWidget);
      expect(find.byType(DailyMetricsView), findsNothing);
      expect(find.text('Piso 1'), findsOneWidget);
      expect(find.text('Hab. 101'), findsOneWidget);

      // A los 59 segundos sin interacción aún no alterna.
      await tester.pump(const Duration(seconds: 59));
      expect(find.byType(FloorMapView), findsOneWidget);
      expect(find.byType(DailyMetricsView), findsNothing);

      // Al cumplirse los 60 segundos alterna suavemente a Estadísticas del Día.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(DailyMetricsView), findsOneWidget);
      expect(find.byType(FloorMapView), findsNothing);
      expect(find.text('75.0%'), findsOneWidget);
      expect(find.text('25 min'), findsOneWidget);

      // Tras otros 60 segundos sin interacción vuelve al Mapa de Pisos.
      await tester.pump(const Duration(seconds: 60));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(FloorMapView), findsOneWidget);
      expect(find.byType(DailyMetricsView), findsNothing);
    });

    testWidgets(
        'Interacción con control remoto reinicia el temporizador de 60 segundos del modo quiosco',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roomsStreamProvider
                .overrideWith((ref) => Stream.value(const <RoomModel>[])),
            pendingTasksStreamProvider
                .overrideWith((ref) => Stream.value(const <TaskModel>[])),
            inProgressTasksStreamProvider
                .overrideWith((ref) => Stream.value(const <TaskModel>[])),
            completedTasksStreamProvider
                .overrideWith((ref) => Stream.value(const <TaskModel>[])),
            notificationsProvider.overrideWith(
              (ref) => Stream.value(const <NotificationModel>[]),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(FloorMapView), findsOneWidget);

      // Transcurren 40s y se recibe una pulsación de control remoto.
      await tester.pump(const Duration(seconds: 40));
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();

      // 25s después (65s totales, solo 25s desde la interacción) NO debe rotar.
      await tester.pump(const Duration(seconds: 25));
      expect(find.byType(FloorMapView), findsOneWidget);
      expect(find.byType(DailyMetricsView), findsNothing);

      // 35s después (60s desde la última interacción) sí debe rotar.
      await tester.pump(const Duration(seconds: 35));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(DailyMetricsView), findsOneWidget);
      expect(find.byType(FloorMapView), findsNothing);
    });
  });
}
