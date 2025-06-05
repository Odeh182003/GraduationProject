buildscript {
    repositories {
        google()
        mavenCentral()
        jcenter() // Optional, but good to include for some older dependencies
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.10") // Use a stable Kotlin version
        classpath("com.google.gms:google-services:4.4.2")
    }
}

subprojects {
    buildDir = file("../../build/${project.name}")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
