import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

kotlin {
    jvmToolchain(17)
}

// La clave de Google Maps no se versiona. Se lee de android/secrets.properties,
// que esta en el .gitignore; copia android/secrets.properties.example y pon la
// tuya. Ver docs/CLAVES.md.
//
// Ojo: esto NO esconde la clave. Viaja dentro del APK igual, porque el SDK de
// Maps la lee del manifiesto en el telefono. Lo unico que la protege de verdad
// es restringirla en Google Cloud Console por paquete + SHA-1.
val archivoSecretos = rootProject.file("secrets.properties")
val secretos = Properties().apply {
    if (archivoSecretos.exists()) {
        archivoSecretos.inputStream().use { load(it) }
    }
}
val claveMaps: String = secretos.getProperty("MAPS_API_KEY") ?: ""

android {
    namespace = "com.elconstructor.ferreteria_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.ferreteria_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Si falta secrets.properties el proyecto compila igual: el mapa sale
        // gris y el log dice "API key not found". Es preferible a un build roto.
        manifestPlaceholders["MAPS_API_KEY"] = claveMaps
    }

    buildTypes {
        release {
            // TODO: esto firma la release con la clave de depuracion. Sirve para
            // probar, pero un APK asi no se puede publicar en Play.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
