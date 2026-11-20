import '../../domain/entities/failure.dart';
import '../../domain/entities/registration.dart';

String? inputMessage(InputIssue? issue) => switch (issue) {
  null => null,
  InputIssue.name => 'Введите имя от 2 до 100 символов',
  InputIssue.email => 'Введите корректный email',
  InputIssue.phone => 'Введите корректный телефон',
  InputIssue.password => 'Пароль: минимум 8 символов',
  InputIssue.emailInUse => 'Этот email уже зарегистрирован.',
  InputIssue.emptyDraft => 'Заполните хотя бы одно поле.',
  InputIssue.invalidRequest => 'Проверьте введённые данные.',
};
String failureMessage(Failure failure) => switch (failure) {
  NetworkFailure() => 'Нет связи с сервером. Проверьте интернет и повторите.',
  ServerFailure() => 'Сервис временно недоступен. Повторите позже.',
  UnauthorizedFailure() => 'Нет доступа. Проверьте аккаунт и повторите.',
  ValidationFailure(:final issue) => inputMessage(issue)!,
  RateLimitFailure() => 'Слишком много попыток. Повторите позже.',
  StorageFailure() =>
    'Не удалось открыть или сохранить черновик. Повторите действие.',
  UnknownFailure() => 'Не удалось выполнить действие. Попробуйте ещё раз.',
};
String pushMessage(PushPhase phase) => switch (phase) {
  PushPhase.initializing => 'Настройка уведомлений…',
  PushPhase.ready => 'FCM подключён. Ожидаем регистрацию.',
  PushPhase.waiting => 'Ожидаем push от сервера.',
  PushPhase.denied => 'Разрешите уведомления в настройках Android.',
  PushPhase.missingToken => 'Токен FCM пока не получен. Повторите запрос.',
  PushPhase.unavailable =>
    'Уведомления недоступны. Проверьте интернет и Google Play Services.',
  PushPhase.sent => 'Сервер отправил push. Ожидаем получение на устройстве.',
  PushPhase.received => 'Push-уведомление получено',
  PushPhase.opened => 'Push-уведомление открыто',
  PushPhase.displayFailed => 'Push получен, но Android не показал уведомление',
  PushPhase.sendFailed => 'Сервер не отправил push. Повторите запрос.',
  PushPhase.statusFailed => 'Не удалось прочитать статус отправки push',
  PushPhase.tokenFailed => 'Не удалось обновить токен. Повторите запрос.',
  PushPhase.requested => 'Запрос push отправлен серверу',
};
