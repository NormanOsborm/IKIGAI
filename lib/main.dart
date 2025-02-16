import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

// import 'package:ikigai_flutter/ikigai/registration/user/registration.dart';
import 'package:ikigai_flutter/ikigai/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "",
        appId: "",
        messagingSenderId: "",
        storageBucket: "",
        projectId: "",
      ));
  try {
    final FirebaseApp app = Firebase.app();
    print('Firebase initialized successfully: ${app.name}');
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  runApp(const GetMaterialApp(
    home: IkigaiApp(),
    debugShowCheckedModeBanner: false,
  ));
}
