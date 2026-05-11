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
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        // Resolve sibling SDKs from the local distribution if available.
        // Used when -PuseLocalSdk is set; otherwise composite build below
        // substitutes the dependency with sibling sources.
        maven {
            name = "localSdk"
            url = uri("${rootDir}/../dist/repo")
        }
    }
}

rootProject.name = "childsdk"

// Live source consumption via composite build. Pass `-PuseLocalSdk` to skip
// this and resolve `com.example.sdk:uisdk` from `../dist/repo` instead.
if (!providers.gradleProperty("useLocalSdk").isPresent) {
    includeBuild("../uisdk")
}
