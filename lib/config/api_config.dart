import 'dart:io';

/// 🌍 CONFIGURATION SECTION

// 🧪 Emulator IP for Android Studio Emulator
const String emulatorHost = "http://10.0.2.2:5000";

// 🖥 Local PC IP address (accessible from real devices over the same Wi-Fi)
const String realDeviceHost = "http://192.168.100.25:5000"; // Change if needed

// 🖥 iOS Simulator or Flutter Web (runs on same machine)
const String localhostHost = "http://localhost:5000";

// 🌐 Public backend via ngrok (works with mobile data, hotspot, etc.)
const String ngrokHost = "https://356b-192-145-175-214.ngrok-free.app"; // Change when you restart ngrok

// ☁️ Optionally, your deployed URL (e.g., Render, Railway)
const String deployedHost = "https://your-production-backend.com"; // Optional for future use

/// 🧠 Choose which host to use below:
/// Set one of the following values to use as active environment:
/// "ngrok", "localEmulator", "localDevice", "localhost", "deployed"
const String activeEnv = "ngrok"; // 👈 Change this to switch environments

/// 🌐 Final baseUrl used in your app
final String baseUrl = () {
  switch (activeEnv) {
    case "ngrok":
      return ngrokHost;
    case "localEmulator":
      return emulatorHost;
    case "localDevice":
      return realDeviceHost;
    case "localhost":
      return localhostHost;
    case "deployed":
      return deployedHost;
    default:
      return ngrokHost; // fallback
  }
}();

/// ⏱ API timeout configuration
const Duration apiTimeout = Duration(seconds: 15);
