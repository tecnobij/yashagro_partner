# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# OneSignal
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# ML Kit
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Flutter Background Service
-keep class id.flutter.flutter_background_service.** { *; }
-dontwarn id.flutter.flutter_background_service.**

# Desugaring & Reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-dontwarn java.lang.invoke.**
