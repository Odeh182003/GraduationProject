buildscript {
    repositories {
        google()
        mavenCentral()
        jcenter()  // Optional, but good to include for some older dependencies
    }
    dependencies {
        // Update Kotlin version to the latest compatible version
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")  // or latest stable version
        classpath("com.google.gms:google-services:4.4.2")
    }
}
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
