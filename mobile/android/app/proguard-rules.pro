# Keep Flutter classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep Kotlin metadata
-keepclassmembers class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Optional: keep React Native classes if your project uses them
-keep class com.facebook.react.** { *; }
-dontwarn com.facebook.react.**
