import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

// import 'package:ikigai_flutter/ikigai/registration/user/registration.dart';
import 'package:ikigai_flutter/ikigai/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCRVfXn4-nJGhORrtYUn9ZkuzPLn7Bh14k",
        appId: "1:1094579124212:android:ca75b7a5c606bbb892aba1",
        messagingSenderId: "",
        storageBucket: "ikigai-24.firebasestorage.app",
        projectId: "ikigai-24",
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
