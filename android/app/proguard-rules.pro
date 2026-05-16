# Google ML Kit - Text Recognition (keep all variants)
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.** { *; }
-keepclassmembers class com.google.mlkit.vision.text.** { *; }

# Google ML Kit commons
-keep class com.google.mlkit.common.** { *; }
-keepclassmembers class com.google.mlkit.common.** { *; }

# Google ML Kit internal
-keep class com.google.mlkit.** { *; }
-keepclassmembers class com.google.mlkit.** { *; }

# Firebase ML Kit dependencies
-keep class com.google.android.gms.** { *; }
-keepclassmembers class com.google.android.gms.** { *; }

# Flutter plugin
-keep class io.flutter.plugins.** { *; }
-keepclassmembers class io.flutter.plugins.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-keepclassmembers class com.google_mlkit_text_recognition.** { *; }

# Google Generative AI
-keep class com.google.ai.generativelanguage.** { *; }
-keepclassmembers class com.google.ai.generativelanguage.** { *; }

# Kotlin specific
-keep class kotlin.** { *; }
-keepclassmembers class kotlin.** { *; }
-keep interface kotlin.** { *; }
