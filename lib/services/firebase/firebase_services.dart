import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';



class FirebaseService {
  // ─── Singleton Instance ─────
  static final FirebaseService _instance = FirebaseService._internal();


  // ─── Private Constructor ─────
  FirebaseService._internal();

  // ─── Factory Constructor ─────
  factory FirebaseService() {
    return _instance;
  }

  static late BuildContext _context;
  static bool _isInitialized = false;

  static Future<FirebaseApp> get firebase =>  Firebase.initializeApp(options: _DefaultFirebaseOptions.currentPlatform,);

  Future<void> init(BuildContext context, {
    FirebaseOptions? android,
    FirebaseOptions? ios,
    FirebaseOptions? macos,
    FirebaseOptions? windows,
    FirebaseOptions? linux,
    FirebaseOptions? web,
  }) async {
    if (_isInitialized) return;

    _context = context;

    try {
      WidgetsFlutterBinding.ensureInitialized();
      // Apply optional configurations before initializing
      if (android != null) _DefaultFirebaseOptions.android = android;
      if (ios != null) _DefaultFirebaseOptions.ios = ios;
      if (macos != null) _DefaultFirebaseOptions.macos = macos;
      if (windows != null) _DefaultFirebaseOptions.windows = windows;
      if (linux != null) _DefaultFirebaseOptions.linux = linux;
      if (web != null) _DefaultFirebaseOptions.web = web;



      await firebase;


      // Optional: Configure Crashlytics if needed
      // FlutterError.onError =
      //     FirebaseCrashlytics.instance.recordFlutterFatalError;

      _isInitialized = true;
      // AppUtils.log("Firebase initialized successfully");
    } catch (e) {
      // AppUtils.log('Firebase initialization error: $e');
    }
  }

  BuildContext get context => _context;
}





class _DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return _web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      case TargetPlatform.macOS:
        return _macos;
      case TargetPlatform.windows:
        return _windows;
      case TargetPlatform.linux:
        return _linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ─── Private Static FirebaseOptions Variables ─────
  static late FirebaseOptions _android;
  static late FirebaseOptions _ios;
  static late FirebaseOptions _macos;
  static late FirebaseOptions _windows;
  static late FirebaseOptions _linux;
  static late FirebaseOptions _web;

  // ─── Setters ─────
  static set android(FirebaseOptions value) => _android = value;
  static set ios(FirebaseOptions value) => _ios = value;
  static set macos(FirebaseOptions value) => _macos = value;
  static set windows(FirebaseOptions value) => _windows = value;
  static set linux(FirebaseOptions value) => _linux = value;
  static set web(FirebaseOptions value) => _web = value;
}

