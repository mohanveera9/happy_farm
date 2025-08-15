# Keep all Razorpay SDK classes and members
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Keep AndroidX Lifecycle classes (Razorpay uses these)
-keep class androidx.lifecycle.DefaultLifecycleObserver
-keep class androidx.lifecycle.ProcessLifecycleOwnerInitializer
-dontwarn androidx.lifecycle.**

# Keep annotation classes
-keepattributes *Annotation*

# Suppress warnings about proguard annotations
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers
