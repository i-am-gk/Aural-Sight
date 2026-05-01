# ===============================
# ✅ Custom ProGuard Rules (for aural_sight)
# ===============================

# --- Keep Vosk (offline speech recognition) classes ---
-keep class org.vosk.** { *; }

# --- Keep ML Kit OCR classes ---
-keep class com.google.mlkit.** { *; }

# --- Keep Google Play Core split components (needed by Flutter engine) ---
-keep class com.google.android.play.core.** { *; }

# --- Keep Flutter engine, plugins, and JNI bridge ---
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# --- Keep AndroidX Lifecycle (for Flutter activities) ---
-keep class androidx.lifecycle.DefaultLifecycleObserver
-keep class androidx.lifecycle.FullLifecycleObserver

# --- Keep all annotations, inner classes, and signatures ---
-keepattributes *Annotation*, Signature, InnerClasses

# --- Prevent reflection-based removals ---
-keepclassmembers class * {
    public <init>(...);
}

# --- Keep TensorFlow Lite (tflite_flutter) ---
-keep class org.tensorflow.** { *; }
-keep class com.google.flatbuffers.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}

# --- Keep flutter_tts (Android TextToSpeech bridge) ---
-keep class com.tundralabs.fluttertts.** { *; }

# --- Keep vibration plugin ---
-keep class xyz.luan.** { *; }
-keep class com.bqviet.** { *; }

# --- Keep record / microphone audio plugin ---
-keep class com.llfbandit.record.** { *; }

# --- Keep permission_handler ---
-keep class com.baseflow.permissionhandler.** { *; }

# --- Suppress warnings for known missing classes ---
-dontwarn org.tensorflow.**
-dontwarn com.google.flatbuffers.**
