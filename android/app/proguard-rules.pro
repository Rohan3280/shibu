# The wallpaper service, widget provider and boot receiver are only ever
# referenced from the manifest, so R8 cannot see that they are used.
-keep class com.shibu.app.wallpaper.** { *; }
-keep class com.shibu.app.widget.** { *; }
-keep class com.shibu.app.rotation.BootReceiver { *; }

# WorkManager instantiates workers reflectively by class name.
-keep class com.shibu.app.rotation.RotationWorker { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { public <init>(...); }

# WorkManager stores its queue in a Room database, and Room resolves the
# generated implementation by reflection: it appends "_Impl" to the database
# class name and looks that up. R8 renames both halves, the lookup misses, and
# the app dies on startup with:
#
#   Failed to create an instance of class androidx.work.impl.WorkDatabase
#
# Keeping the names is what makes a minified release build survive launch.
-keep class androidx.work.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class **_Impl { *; }
-dontwarn androidx.room.paging.**
