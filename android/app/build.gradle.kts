plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.e3dady"
    compileSdk = 35  // ✅ حدد رقم ثابت بدل flutter.compileSdkVersion

    // ✅ امسح سطر ndkVersion أو علقه
    // ndkVersion = "25.2.9519653"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.e3dady"
        minSdk = 21
        targetSdk = 35  // ✅ حدد رقم ثابت
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation "androidx.work:work-runtime:2.8.1"
}
