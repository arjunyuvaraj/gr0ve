import java.util.Properties
import java.io.FileInputStream
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.arjunyuvaraj.gr0ve"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.arjunyuvaraj.gr0ve"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = "1.0" //flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    signingConfigs {
        create("release") {
            val keyPropsFile = rootProject.file("key.properties")
            val keyProps = Properties()

            if (keyPropsFile.exists()) {
                FileInputStream(keyPropsFile).use { keyProps.load(it) }
                println("Loaded key.properties for release signing.")

                storeFile = file(keyProps.getProperty("storeFile") ?: throw GradleException("storeFile missing in key.properties"))
                keyAlias = keyProps.getProperty("keyAlias") ?: throw GradleException("keyAlias missing in key.properties")
                keyPassword = keyProps.getProperty("keyPassword") ?: throw GradleException("keyPassword missing in key.properties")
                storePassword = keyProps.getProperty("storePassword") ?: throw GradleException("storePassword missing in key.properties")
            } else {
                println("Warning: key.properties not found. Using debug keystore.")
                storeFile = file("${System.getProperty("user.home")}/.android/debug.keystore")
                keyAlias = "androiddebugkey"
                keyPassword = "android"
                storePassword = "android"
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("debug") {
            // debug uses default debug keystore automatically
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    implementation(platform("com.google.firebase:firebase-bom:33.4.0"))
    implementation("com.google.firebase:firebase-auth")
}
