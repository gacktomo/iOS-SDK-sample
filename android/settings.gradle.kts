pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}
plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

rootProject.name = "android-sdk-rollup"

// Roll-up build that composes all SDKs. Each SDK is a standalone Gradle build
// (own settings.gradle.kts + wrapper) — open them individually in Android Studio
// or run `./gradlew :uisdk:publish` from here to publish all three at once.
includeBuild("uisdk")
includeBuild("childsdk")
includeBuild("parentsdk")
