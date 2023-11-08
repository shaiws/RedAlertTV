plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "shaiws.redalert"
    compileSdk = 34
    buildFeatures {
        buildConfig = true
    }
    defaultConfig {
        applicationId = "shaiws.redalert"
        minSdk = 28
        targetSdk = 33
        versionCode = 12
        versionName = "1.1.1"
        proguardFiles()

    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
}

dependencies {

    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.leanback:leanback:1.0.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation ("com.squareup.okhttp3:okhttp:5.0.0-alpha.11")
     implementation ("com.google.android.material:material:1.10.0")
    implementation("androidx.drawerlayout:drawerlayout:1.2.0")
    implementation("com.android.car.ui:car-ui-lib:2.5.1")


}
