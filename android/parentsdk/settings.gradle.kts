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
        maven {
            name = "localSdk"
            url = uri("${rootDir}/../dist/repo")
        }
    }
}

rootProject.name = "parentsdk"

// Live source consumption via composite build. Pass `-PuseLocalSdk` to skip
// this and resolve sibling SDK artifacts from `../dist/repo` instead.
if (!providers.gradleProperty("useLocalSdk").isPresent) {
    includeBuild("../uisdk")
    includeBuild("../childsdk")
}
