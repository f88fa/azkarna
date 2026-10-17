# flutter_local_notifications: keep scheduled notification payload classes.
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# Gson (used by flutter_local_notifications) needs generic signatures.
-keepattributes Signature
-keepattributes *Annotation*
