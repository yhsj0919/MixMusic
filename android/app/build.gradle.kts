import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties()
val signingPropertiesFile = rootProject.file("key.properties")
if (signingPropertiesFile.exists()) {
    signingPropertiesFile.reader(Charsets.UTF_8).use { signingProperties.load(it) }
}
val releaseKeystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
    ?: signingProperties.getProperty("storeFile")

android {
    namespace = "com.example.mix_music"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.mix_music.v2"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (!releaseKeystorePath.isNullOrBlank()) {
            create("release") {
                storeFile = rootProject.file(releaseKeystorePath)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                    ?: signingProperties.getProperty("storePassword")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                    ?: signingProperties.getProperty("keyAlias")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
                    ?: signingProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (releaseKeystorePath.isNullOrBlank()) "debug" else "release"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
