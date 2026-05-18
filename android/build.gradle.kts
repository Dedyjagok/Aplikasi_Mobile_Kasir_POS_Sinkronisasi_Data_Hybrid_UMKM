allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
  // Add the dependency for the Google services Gradle plugin
  id("com.google.gms.google-services") version "4.4.4" apply false
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Auto-assign namespace for libraries without one
    // Must be before evaluationDependsOn
    afterEvaluate {
        val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (android != null && android.namespace == null) {
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                try {
                    val packageLine = manifestFile.readLines().find { it.contains("package=") }
                    val packageName = packageLine?.substringAfter("package=\"")?.substringBefore("\"")
                    if (packageName != null) {
                        android.namespace = packageName
                    }
                } catch (e: Exception) {
                    // Silently ignore if parsing fails
                }
            }
        }
    }
    
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}