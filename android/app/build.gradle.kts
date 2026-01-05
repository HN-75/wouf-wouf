plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.woufwouf.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.woufwouf.app"
        minSdk = 24  // Minimum pour TFLite et Bluetooth LE
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Support pour TensorFlow Lite
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    buildTypes {
        release {
            // Signing avec les clés debug pour l'instant
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    // Éviter les conflits de fichiers natifs
    packaging {
        resources {
            excludes += listOf("META-INF/DEPENDENCIES", "META-INF/LICENSE", "META-INF/LICENSE.txt")
        }
    }
}

flutter {
    source = "../.."
}
