plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val bundledAiModelSourceDirectory =
    rootProject.projectDir.resolve("../../ai_models").canonicalFile
val bundledAiModelFiles =
    listOf(
        "intent_classifier.onnx",
        "intent_classifier.json",
        "gemma3-1b-it-int4.litertlm",
        "gemma3-1b-it-int4.json",
    )
val generatedBundledAiAssetsDirectory =
    layout.buildDirectory.dir("generated/assets/bundledAiModels")
val bundleAiModels =
    providers.gradleProperty("bundleAiModels")
        .map { it.toBoolean() }
        .orElse(bundledAiModelFiles.all { bundledAiModelSourceDirectory.resolve(it).isFile })

val stageBundledAiModels = tasks.register("stageBundledAiModels") {
    group = "build"
    description = "Stages local AI artifacts as Android assets when available."
    inputs.files(bundledAiModelFiles.map { bundledAiModelSourceDirectory.resolve(it) })
    inputs.property("bundleAiModels", bundleAiModels)
    outputs.dir(generatedBundledAiAssetsDirectory)
    doLast {
        project.delete(generatedBundledAiAssetsDirectory)
        if (!bundleAiModels.get()) {
            logger.lifecycle("AI model bundling disabled or model artifacts are absent")
            return@doLast
        }
        val missing = bundledAiModelFiles.filterNot {
            bundledAiModelSourceDirectory.resolve(it).isFile
        }
        check(missing.isEmpty()) {
            "bundleAiModels=true but required artifacts are missing from " +
                "${bundledAiModelSourceDirectory.path}: ${missing.joinToString()}"
        }
        project.copy {
            from(bundledAiModelSourceDirectory) {
                include(
                    "intent_classifier.onnx",
                    "intent_classifier.json",
                    "gemma3-1b-it-int4.litertlm",
                    "gemma3-1b-it-int4.json",
                )
                into("ai")
            }
            into(generatedBundledAiAssetsDirectory)
        }
        logger.lifecycle("Bundled AI assets staged from ${bundledAiModelSourceDirectory.path}")
    }
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

    sourceSets.getByName("main").assets.srcDir(generatedBundledAiAssetsDirectory.get().asFile)

    androidResources {
        noCompress += "litertlm"
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
    testImplementation("junit:junit:4.13.2")
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

tasks.matching {
    it.name == "preBuild" ||
        (it.name.startsWith("merge") && it.name.endsWith("Assets"))
}.configureEach {
    dependsOn(stageBundledAiModels)
}
