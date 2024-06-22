import java.util.Locale

pluginManagement {
    repositories {
        gradlePluginPortal()
        maven("https://papermc.io/repo/repository/maven-public/")
        // io.github.goooler.shadow
        maven("https://plugins.gradle.org/m2/")
    }
}

rootProject.name = "vine"
for (name in listOf("Vine-API", "Vine-Server")) {
    val projName = name.lowercase(Locale.ENGLISH)
    include(projName)
    findProject(":$projName")!!.projectDir = file(name)
}
