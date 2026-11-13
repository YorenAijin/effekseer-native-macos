# EffekseerNativeForJava pour macOS (OPBS)

EffekseerCraft (`EffekseerCraft-DEFINITIVE.jar`, mod `efscraft` 0.3.5.1.11) n'embarque sa bibliothèque native que pour Windows x64. Sur Mac, le jeu crashe au chargement des mods (« Unable to load resource stream from jar file »).

Ce dépôt compile cette bibliothèque pour macOS x86_64 avec GitHub Actions (un Mac de GitHub) :

- même code que la DLL Windows du jar : `effekseer/EffekseerForMultiLanguages` au commit `76694511` (juillet 2023), seule version qui exporte exactement les mêmes fonctions JNI ;
- seul changement : le moteur de rendu OpenGL2 au lieu d'OpenGL3, car Minecraft 1.12.2 n'a qu'OpenGL 2.1 sur Mac ;
- la CI vérifie que la bibliothèque exporte exactement les 65 fonctions JNI de la DLL Windows (`expected-jni-exports.txt`).

Résultat : l'artefact `effekseer-native-macos-x86_64` de l'onglet Actions (`native/macos/x86_64/libEffekseerNativeForJava.dylib`).

Le chargeur Java du mod ne connaît que Windows et Linux : `loader/EffekSeer4J.java` est sa version modifiée (code MIT de MrMks/Effekseer4J) qui charge `native/macos/x86_64/libEffekseerNativeForJava.dylib` sur Mac. Seule la classe `EffekSeer4J$Library` est remplacée dans le jar.
