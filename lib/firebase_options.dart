// ЗАГЛУШКА. Цей файл генерує FlutterFire CLI:
//   flutterfire configure --platforms=web
// Команда перезапише його реальною конфігурацією вашого проєкту Firebase.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Firebase ще не налаштовано: виконайте `flutterfire configure`.',
  );
}
