# Keep Stripe SDK classes to prevent R8 from removing them
-keep class com.stripe.** { *; }
-dontwarn com.stripe.**

# Keep Flutter classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep Kotlin metadata
-keepclassmembers class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Optional: keep React Native classes if your project uses them
-keep class com.facebook.react.** { *; }
-dontwarn com.facebook.react.**
