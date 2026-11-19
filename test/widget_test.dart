import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_smart_app/main.dart';
import 'package:hotel_smart_app/models/notification_model.dart';
import 'package:hotel_smart_app/models/task_model.dart';
import 'package:hotel_smart_app/providers/notifications_provider.dart';
import 'package:hotel_smart_app/providers/tasks_provider.dart';
import 'package:hotel_smart_app/screens/home_screen.dart';
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

    test('marca active == false cuando isAcknowledged == true y detecta baja prioridad',
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

      // Verifica que el banner está visible en la parte superior con cuarto y motivo.
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
            pendingTasksStreamProvider.overrideWith(
              (ref) => Stream.value(const <TaskModel>[]),
            ),
            inProgressTasksStreamProvider.overrideWith(
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
}
