pluginManagement {
    def flutterSdkPath = {
        def plugins = new Properties()
        file("..\\..\\android\\local.properties").withInputStream { stream ->
            plugins.load(stream)
        }
        def flutterSdkPath = plugins.getProperty("flutter.sdk")
        if (flutterSdkPath == null) {
            throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
        }
        return flutterSdkPath
    }()

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.2.0" apply false
    id "org.jetbrains.kotlin.android" version "2.0.0" apply false  // ✅ Kotlin 2.0.0
}

include ":app"
