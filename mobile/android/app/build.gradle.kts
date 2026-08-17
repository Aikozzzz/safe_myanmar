plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "org.safemyanmar.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.safemyanmar.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

dependencies {
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.27.0")
    implementation("com.google.ai.edge.litertlm:litertlm-android:0.16.0")
}

val verifyDebugMergedManifest by tasks.registering {
    group = "verification"
    description = "Checks safety-sensitive permissions in the merged debug manifest."
    dependsOn("processDebugMainManifest")
    doLast {
        val mergedManifest = layout.buildDirectory
            .dir("intermediates/merged_manifest/debug")
            .get()
            .asFile
            .walkTopDown()
            .firstOrNull {
                it.isFile &&
                    it.name == "AndroidManifest.xml" &&
                    it.path.contains("processDebugMainManifest")
            }
            ?: error("Merged debug AndroidManifest.xml was not generated")
        val manifest = mergedManifest.readText()
        listOf(
            "android.permission.INTERNET",
            "android.permission.ACCESS_COARSE_LOCATION",
            "android.permission.ACCESS_FINE_LOCATION",
            "android.permission.ACCESS_NETWORK_STATE",
            "android.permission.ACCESS_WIFI_STATE",
            "android.permission.BLUETOOTH",
            "android.permission.BLUETOOTH_ADMIN",
            "android.permission.BLUETOOTH_SCAN",
            "android.permission.BLUETOOTH_ADVERTISE",
            "android.permission.BLUETOOTH_CONNECT",
            "android.permission.POST_NOTIFICATIONS",
            "android.permission.FOREGROUND_SERVICE",
            "android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE",
            "android.permission.SEND_SMS",
        ).forEach { permission ->
            check(permission in manifest) { "Expected merged permission missing: $permission" }
        }
        listOf(
            "android.permission.ACCESS_BACKGROUND_LOCATION",
            "android.permission.READ_SMS",
            "android.permission.RECEIVE_SMS",
            "android.permission.READ_CONTACTS",
        ).forEach { permission ->
            check(permission !in manifest) { "Prohibited merged permission: $permission" }
        }
        check("android:glEsVersion=\"0x00030000\"" in manifest)
        check(
            Regex(
                "glEsVersion=\\\"0x00030000\\\"[\\s\\S]*?required=\\\"true\\\"",
            ).containsMatchIn(manifest),
        )
    }
}

tasks.matching { it.name == "assembleDebug" }.configureEach {
    dependsOn(verifyDebugMergedManifest)
}
