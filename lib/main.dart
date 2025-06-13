import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/firebase_service.dart';
import '../config/env_config.dart';
import '../module/myapp.dart';
import '../services/notification_service.dart';
import '../utils/menu_parser.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("🔔 Handling a background message: ${message.messageId}");
    print("📝 Message data: ${message.data}");
    print("📌 Notification: ${message.notification?.title}");
  }
}

// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   if (kDebugMode) {
//     print("🔔 Background message: ${message.messageId}");
//   }
// }

Future<String?> getAndroidFirebasePackageName() async {
  try {
    final jsonStr = await rootBundle.loadString('assets/google-services.json');
    final data = json.decode(jsonStr);
    return data['client']?[0]?['client_info']?['android_client_info']?['package_name'];
  } catch (e) {
    debugPrint("⚠️ Error reading google-services.json: $e");
    return null;
  }
}

Future<String?> getIosFirebaseBundleId() async {
  try {
    final byteData = await rootBundle.load('assets/GoogleService-Info.plist');
    final plistData = const Utf8Decoder().convert(byteData.buffer.asUint8List());
    final bundleIdRegex = RegExp(r'<key>BUNDLE_ID<\/key>\s*<string>(.*?)<\/string>');
    final match = bundleIdRegex.firstMatch(plistData);
    return match?.group(1);
  } catch (e) {
    debugPrint("⚠️ Error reading GoogleService-Info.plist: $e");
    return null;
  }
}

Future<bool> assetExists(String path) async {
  try {
    await rootBundle.load(path);
    return true;
  } catch (_) {
    return false;
  }
}
void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Lock orientation to portrait only
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Initialize local notifications first
    await initLocalNotifications();

    if (pushNotify) {
      try {
        final info = await PackageInfo.fromPlatform();

        if (defaultTargetPlatform == TargetPlatform.android) {
          final exists = await assetExists('assets/google-services.json');
          if (!exists) {
            runApp(_missingFirebaseFileScreen("google-services.json"));
            return;
          }

          final gsPackage = await getAndroidFirebasePackageName();
          if (gsPackage != null && gsPackage != info.packageName) {
            runApp(_firebaseErrorScreen(
              title: "Android Firebase Mismatch",
              expected: gsPackage,
              actual: info.packageName,
            ));
            return;
          }
        }

        if (defaultTargetPlatform == TargetPlatform.iOS) {
          final exists = await assetExists('assets/GoogleService-Info.plist');
          if (!exists) {
            runApp(_missingFirebaseFileScreen("GoogleService-Info.plist"));
            return;
          }

          final iosBundleId = await getIosFirebaseBundleId();
          if (iosBundleId != null && iosBundleId != info.packageName) {
            runApp(_firebaseErrorScreen(
              title: "iOS Firebase Mismatch",
              expected: iosBundleId,
              actual: info.packageName,
            ));
            return;
          }
        }

        final options = await loadFirebaseOptionsFromJson();
        await Firebase.initializeApp(options: options);
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        await initializeFirebaseMessaging();
        debugPrint("✅ Firebase initialized successfully");
      } catch (e) {
        debugPrint("❌ Firebase initialization error: $e");
      }
    } else {
      debugPrint("🚫 Firebase not initialized (pushNotify: $pushNotify, isWeb: $kIsWeb)");
    }

    if (webUrl.isEmpty) {
      debugPrint("❗ Missing WEB_URL environment variable.");
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(child: Text("WEB_URL not configured.")),
        ),
      ));
      return;
    }

    debugPrint("""
      🛠 Runtime Config:
      - pushNotify: $pushNotify
      - webUrl: $webUrl
      - isSplash: $isSplashEnabled,
      - splashLogo: $splashUrl,
      - splashBg: $splashBgUrl,
      - splashDuration: $splashDuration,
      - splashAnimation: $splashAnimation,
      - taglineColor: $splashTaglineColor,
      - spbgColor: $splashBgColor,
      - isBottomMenu: $isBottomMenu,
      - bottomMenuItems: ${parseBottomMenuItems(bottomMenuRaw)},
      - isDeeplink: $isDeepLink,
      - backgroundColor: $bottomMenuBgColor,
      - activeTabColor: $bottomMenuActiveTabColor,
      - textColor: $bottomMenuTextColor,
      - iconColor: $bottomMenuIconColor,
      - iconPosition: $bottomMenuIconPosition,
      - Permissions:
        - Camera: $isCameraEnabled
        - Location: $isLocationEnabled
        - Mic: $isMicEnabled
        - Notification: $isNotificationEnabled
        - Contact: $isContactEnabled
      """);

    runApp(MyApp(
      webUrl: webUrl,
      isSplash: isSplashEnabled,
      splashLogo: splashUrl,
      splashBg: splashBgUrl,
      splashDuration: splashDuration,
      splashAnimation: splashAnimation,
      taglineColor: splashTaglineColor,
      spbgColor: splashBgColor,
      isBottomMenu: isBottomMenu,
      bottomMenuItems: bottomMenuRaw,
      isDeeplink: isDeepLink,
      backgroundColor: bottomMenuBgColor,
      activeTabColor: bottomMenuActiveTabColor,
      textColor: bottomMenuTextColor,
      iconColor: bottomMenuIconColor,
      iconPosition: bottomMenuIconPosition,
      isLoadIndicator: isLoadIndicator,
    ));
  } catch (e, stackTrace) {
    debugPrint("❌ Fatal error during initialization: $e");
    debugPrint("Stack trace: $stackTrace");
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text("Error: $e")),
      ),
    ));
  }
}
Widget _firebaseErrorScreen({required String title, required String expected, required String actual}) {
  return MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: Text("Firebase Configuration Error")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("❌ $title", style: TextStyle(fontSize: 20, color: Colors.red)),
            SizedBox(height: 20),
            Text("Expected: $expected", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text("Actual: $actual", style: TextStyle(fontSize: 16)),
            SizedBox(height: 30),
            Text("Fix your Firebase configuration before proceeding.", textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

Widget _missingFirebaseFileScreen(String fileName) {
  return MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: Text("Missing Firebase File")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            "❌ Firebase Configuration File is missing: $fileName",
            style: TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}