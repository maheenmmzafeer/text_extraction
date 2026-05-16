// Root build.gradle.kts

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        configurations.all {
            resolutionStrategy.eachDependency {
                if (requested.group == "androidx.activity") {
                    useVersion("1.9.3")
                }
                if (requested.group == "androidx.core") {
                    useVersion("1.13.1")
                }
                if (requested.group.startsWith("androidx.navigation")) {
                    useVersion("2.7.7")
                }
            }
        }
    }
}

subprojects {
    afterEvaluate {
        tasks.withType<com.android.build.gradle.internal.tasks.CheckAarMetadataTask>().configureEach {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
