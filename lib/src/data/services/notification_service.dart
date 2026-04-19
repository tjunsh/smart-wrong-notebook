import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';

class NotificationService {
  NotificationService({required QuestionRepository questionRepository})
      : _questionRepository = questionRepository;

  final QuestionRepository _questionRepository;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
  }

  Future<void> checkAndNotify() async {
    await init();
    final all = await _questionRepository.listAll();
    final dueCount = all.where((q) => q.masteryLevel != MasteryLevel.mastered).length;

    if (dueCount > 0) {
      await _plugin.show(
        0,
        '错题本复习提醒',
        '你有 $dueCount 道错题待复习，快来巩固吧！',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'review_reminder',
            '复习提醒',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
