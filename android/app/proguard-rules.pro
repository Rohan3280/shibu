# The wallpaper service, widget provider and boot receiver are only ever
# referenced from the manifest, so R8 cannot see that they are used.
-keep class com.shibu.app.wallpaper.** { *; }
-keep class com.shibu.app.widget.** { *; }
-keep class com.shibu.app.rotation.BootReceiver { *; }

# WorkManager instantiates workers reflectively by class name.
-keep class com.shibu.app.rotation.RotationWorker { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { public <init>(...); }
