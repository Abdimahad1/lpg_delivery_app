import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// 🌍 Choose which environment to use:
/// Options: "ngrok", "localEmulator", "localDevice", "localhost", "deployed"
const String? overrideEnv = "ngrok"; // ✅ Using ngrok for real device testing

// 🛰️ Your base URLs per environment
const String emulatorHost = "http://10.0.2.2:5000"; // Android Emulator
const String realDeviceHost = "http://192.168.6.25:5000"; // Laptop IP
const String localhostHost = "http://localhost:5000"; // Browsers / dev machine
const String ngrokHost = "https://2c8d-192-145-170-150.ngrok-free.app"; // ✅ Active ngrok URL
const String deployedHost = "https://your-production-backend.com"; // Live backend (future)

// 📡 Final base URL with `/api/` included (backend uses `/api/auth`)
final String baseUrl = (() {
  String raw;

  if (overrideEnv != null) {
    switch (overrideEnv) {
      case "ngrok":
        raw = ngrokHost;
        break;
      case "localEmulator":
        raw = emulatorHost;
        break;
      case "localDevice":
        raw = realDeviceHost;
        break;
      case "localhost":
        raw = localhostHost;
        break;
      case "deployed":
        raw = deployedHost;
        break;
      default:
        raw = ngrokHost;
    }
  } else {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS) {
      raw = localhostHost;
    } else if (Platform.isAndroid) {
      raw = emulatorHost;
    } else {
      raw = ngrokHost;
    }
  }

  if (!raw.endsWith('/')) raw += '/';
  raw += 'api/'; // ✅ Include /api/
  print("📡 baseUrl: $raw");
  return raw;
})();

const Duration apiTimeout = Duration(seconds: 15);
