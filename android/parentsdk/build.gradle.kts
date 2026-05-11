plugins {
    alias(libs.plugins.android.library)
    `maven-publish`
}

group = "com.example.sdk"
version = "1.0.0"

android {
    namespace = "com.example.parentsdk"
    compileSdk {
        version = release(36) {
            minorApiLevel = 1
        }
    }

    defaultConfig {
        minSdk = 24
        consumerProguardFiles("consumer-rules.pro")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    publishing {
        singleVariant("release") {
            withSourcesJar()
        }
    }
}

dependencies {
    api("com.example.sdk:childsdk:1.0.0")
    implementation(libs.androidx.core.ktx)
}

afterEvaluate {
    publishing {
        publications {
            register<MavenPublication>("release") {
                from(components["release"])
            }
        }
        repositories {
            maven {
                name = "local"
                url = uri("${rootDir}/../dist/repo")
            }
        }
    }
}
