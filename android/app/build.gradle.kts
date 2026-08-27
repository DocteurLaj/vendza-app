import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun isReleaseTaskRequested(): Boolean {
    return gradle.startParameter.taskNames.any { raw ->
        val task = raw.substringAfterLast(':').lowercase()
        (task.contains("assemble") || task.contains("bundle") || task.contains("install")) &&
            task.contains("release")
    }
}

fun requireReleaseSigningConfigured() {
    if (!keystorePropertiesFile.exists()) {
        throw GradleException(
            "Release build blocked: Android signing is not configured. " +
                "Missing android/key.properties. See docs/RELEASE_SIGNING.md.",
        )
    }
    val required = listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
    for (key in required) {
        val value = keystoreProperties.getProperty(key)?.trim()
        if (value.isNullOrEmpty()) {
            throw GradleException(
                "Release build blocked: Android signing is not configured. " +
                    "Missing '$key' in android/key.properties.",
            )
        }
    }
    val storePath = keystoreProperties.getProperty("storeFile")!!.trim()
    val store = file(storePath)
    if (!store.isFile) {
        throw GradleException(
            "Release build blocked: Android signing is not configured. " +
                "Keystore file not found: $storePath",
        )
    }
}

// Fail during configuration for release tasks — before dependency downloads.
if (isReleaseTaskRequested()) {
    requireReleaseSigningConfigured()
}

android {
    namespace = "app.vendza.marketplace"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "app.vendza.marketplace"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Never fall back to the debug keystore for release artifacts.
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
