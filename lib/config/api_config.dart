import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// 🌍 Choose which environment to use:
/// Options: "ngrok", "localEmulator", "localDevice", "localhost", "deployed"
const String? overrideEnv = "deployed"; // ✅ Now using deployed backend

// 🛰️ Your base URLs per environment
const String emulatorHost = "http://10.0.2.2:5000"; // Android Emulator
const String realDeviceHost = "http://192.168.6.25:5000"; // Laptop IP
const String localhostHost = "http://localhost:5000"; // Browsers / dev machine
const String ngrokHost = "https://afdc-192-145-175-167.ngrok-free.app"; // Old testing tunnel
const String deployedHost = "https://lgb-delivery-backend.onrender.com"; // ✅ Live backend

// 📡 Final base URL with `/api/` included
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
  raw += 'api/'; // ✅ Append /api/
  print("📡 baseUrl: $raw");
  return raw;
})();

const Duration apiTimeout = Duration(seconds: 15);
