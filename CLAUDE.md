# Trigonometry

Petit utilitaire macOS de Vincent Jalby (2004-2008 en Objective-C/nib, réécrit en Swift/SwiftUI en 2026) qui affiche le cercle trigonométrique : on fait glisser le point M sur le cercle et l'application montre l'angle θ, son cosinus et son sinus.

L'utilisateur parle français : répondre en français. Les commentaires du code sont en français.

## État

- Version 1.4, macOS 13 minimum, binaire universel arm64 + x86_64.
- Identifiant `org.jalby.trigonometry`, signature ad hoc (`CODE_SIGN_IDENTITY = "-"`, style manuel), hardened runtime. Pas de sandbox, pas d'entitlements, pas de notarisation.
- Dépôt git (branche `main`), destiné à https://github.com/vjalby/Trigonometry. Les archives (`Legacy/`, `Trigonometry-1.3-original.zip`) restent sur la machine de l'auteur et sont exclues par `.gitignore`, comme `build/` et `Trigonometry.app`. Il n'y a ni tests ni CI.
- Copyright « Vincent Jalby » partout. L'ancien nom « VoJou Software » a été retiré à la demande de l'auteur : ne pas le réintroduire.

## Historique de la modernisation (10 octobre 2026)

Tout a été fait en une seule journée, en deux étapes, à partir de la version 1.3 de 2008 (Objective-C, nibs Interface Builder 2, SDK 10.4, PowerPC/Intel 32 bits).

1. **Mise à jour du code Objective-C** (conservée dans `Legacy/ObjC-1.4/`, macOS 12 minimum) :
   - passage en ARC et en 64 bits, remplacement des API obsolètes (`NSOnState`, `openFile:`, constante `pi`) ;
   - correction d'un débordement de tableau dans le tracé des pointillés (`float array[1]` recevant deux valeurs, passé de plus à une API qui attend des `CGFloat`) ;
   - interface reconstruite en code, parce que Xcode ne sait plus ouvrir les anciens nibs et que le nib français était vide ;
   - origine du repère gérée par une transformation dans le dessin plutôt que par `translateOriginToPoint:` ;
   - prise en charge du mode sombre, impression toujours en couleurs claires ;
   - nouveau projet Xcode, `English.lproj` renommé `en.lproj`, fichiers `.strings` convertis d'UTF-16 en UTF-8.
2. **Réécriture en Swift/SwiftUI** (le code actuel), qui a fait passer le minimum à macOS 13 (scène `Window`, `ImageRenderer`).

Changements visibles par rapport à la 1.3, tous voulus :

- le menu Édition d'origine et le lien « VoJou Software WEB site » du menu Aide ont disparu ; SwiftUI fournit ses menus standard ;
- l'encadré θ / cos / sin est aligné sur le signe « = » au lieu d'un calage par espaces ;
- en degrés, les étiquettes n'ont plus d'espaces de remplissage (`%.0f°` au lieu de `%3.0f°`) ;
- l'identifiant est passé de `com.vojousoftware.trigonometry` à `org.jalby.trigonometry` (les trois réglages ont été recopiés à la main sur la machine de l'auteur) ;
- nouvelle icône (cercle trigonométrique blanc sur fond bleu, rayon vert), l'ancienne plafonnait à 128 px ;
- ReadMe mis à jour : version 1.4, configuration requise, site https://vincent.jalby.org.

## Sources

Quatre fichiers Swift à la racine, sans dépendance externe.

| Fichier | Rôle |
|---|---|
| `TrigoModel.swift` | `TrigoModel` (ObservableObject) : `theta`, `point` (M dans le repère du cercle, rayon 1), `isDragging`. Logique de glisser, accrochage aux angles remarquables, écriture de l'angle (`label(for:unit:)`). Enum `AngleUnit` (0 radian, 1 degré). |
| `TrigoView.swift` | Dessin complet dans un `Canvas` (struct privée `TrigoDrawing`), palette clair/sombre (`Palette`), encadré θ / cos / sin. |
| `ContentView.swift` | Contenu de la fenêtre : `TrigoView` + `DragGesture`, radio Radians/Degrés, deux cases à cocher. Contient aussi l'impression (`TrigoPrintView`, `makePrintView`, `printDiagram`). |
| `TrigonometryApp.swift` | `@main`, scène `Window` unique, menus Format d'impression (⇧⌘P), Imprimer (⌘P) et Aide (⌘?, ouvre le `ReadMe.rtf` localisé du bundle). |

Préférences via `@AppStorage`, déclarées à la fois dans `ContentView` et dans `TrigonometryApp` (qui en a besoin pour l'impression) : `prefs_angleUnit` (Int, 0 ou 1), `prefs_standardAngles`, `prefs_sinCos`. Ces clés sont celles de la version d'origine ; les garder.

### Comportement à préserver

La logique de glisser est portée à l'identique de l'original (comparer avec `Legacy/ObjC-1.4/TrigoView.m` en cas de doute).

- Un glisser ne démarre que si le clic tombe sur le cercle (carré de la norme entre 0,9 et 1,1) ; sinon bip, et le geste est ignoré jusqu'au relâchement.
- θ parcourt ]−2π, 2π[ : l'orientation (signe de θ) est conservée quand on franchit le demi-axe négatif. θ ≥ 0 se dessine en rouge, θ < 0 en bleu.
- Un clic sur (1, 0) ramène θ à 0 (et non à ±2π).
- Accrochage au multiple le plus proche de π, π/2, π/3, π/4, π/6 (testés dans cet ordre) à 0,075 rad près. Hors accrochage, l'angle s'écrit avec deux décimales.
- Avec « Afficher sin/cos » : les projections en pointillés et leurs valeurs sont masquées pendant le glisser et quand M est sur un axe ; l'encadré en haut à droite reste affiché.
- L'encadré donne les valeurs exactes 1/2, √2/2 et √3/2, détectées par comparaison à 0,5, 0,7071 et 0,866 à 10⁻⁴ près (ce qui marche parce que l'angle a été accroché avant).
- Impression : rayon = min(largeur, hauteur)/4 au lieu de /3, ni fond ni bordure, palette claire forcée, marges de 33 pt, dessin centré.

### Pièges du dessin

- Le texte du Canvas est en Helvetica à taille fixe (`fixedSize`, minimum 9 pt) via `Text(verbatim:)` : il n'est ni localisé ni soumis à Dynamic Type. Les nombres utilisent `String(format:)` (point décimal dans les deux langues, comme l'original).
- Le signe moins et la barre de fraction sont les caractères U+2212 et U+2215 (`TrigoModel.minus`, `TrigoModel.div`), pas `-` et `/`.
- Le radical est bricolé : « √ » suivi d'un tiret cadratin remonté par `baselineOffset` et ramené au-dessus du nombre par un `kerning` négatif, les deux calculés d'après les dimensions du tiret en Helvetica (`squareRoot(of:size:)`). Tout changement de police ou de taille demande de revérifier le rendu visuellement.
- Les trois lignes de l'encadré sont alignées sur le signe « = » et posées sur leur ligne de base à la main (`firstBaseline`).
- L'impression est vectorielle : `ImageRenderer` rejoue le dessin SwiftUI dans le `CGContext` de la `TrigoPrintView` (une `NSView`). Ne pas la remplacer par une image bitmap.

## Localisation

- `en.lproj` et `fr.lproj`, région de développement `en`.
- Les chaînes anglaises du code servent de clés. `en.lproj/Localizable.strings` ne contient qu'un commentaire ; toute nouvelle chaîne d'interface doit être ajoutée dans `fr.lproj/Localizable.strings`.
- `InfoPlist.strings` (UTF-8) : nom du bundle et copyright « © Vincent Jalby, 2004-2026 », à tenir à jour dans les deux langues.
- `ReadMe.rtf` dans chaque langue, sert d'aide ; pointe vers https://vincent.jalby.org.

## Projet Xcode

`Trigonometry.xcodeproj/project.pbxproj` est écrit à la main : format classique (`objectVersion = 56`), références de fichiers explicites, identifiants de la forme `AA00…`, pas de groupes synchronisés.

- **Ajouter un fichier source ne suffit pas** : il faut l'inscrire dans le pbxproj (PBXFileReference, PBXBuildFile, groupe Sources, phase Sources). Idem pour une ressource (phase Resources, et PBXVariantGroup si elle est localisée).
- `Info.plist` est explicite (`GENERATE_INFOPLIST_FILE = NO`) et tire ses valeurs des réglages de build. Le numéro de version se change dans le pbxproj : `MARKETING_VERSION` et `CURRENT_PROJECT_VERSION`, dans les deux configurations de la cible (Debug et Release). `LSMinimumSystemVersion` suit `MACOSX_DEPLOYMENT_TARGET`.
- Pas de scheme partagé : `xcodebuild` crée automatiquement le scheme `Trigonometry`.
- `xcuserdata/` est propre à la machine.

## Build

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Trigonometry.xcodeproj -scheme Trigonometry -configuration Release -derivedDataPath build/DerivedData ONLY_ACTIVE_ARCH=NO build
```

Puis copier le résultat à la racine :

```bash
rm -rf Trigonometry.app && cp -R build/DerivedData/Build/Products/Release/Trigonometry.app Trigonometry.app
```

- Le préfixe `DEVELOPER_DIR` est nécessaire quand `xcode-select -p` pointe sur les Command Line Tools (cas de la machine où le projet a été modernisé, avec Xcode 27) ; il est inoffensif sinon. L'auteur travaille sur deux machines : vérifier plutôt que supposer.
- Les avertissements CoreSimulator / CoreDevice de `xcodebuild` sont du bruit sans rapport.
- `build/` est régénérable. `Trigonometry.app` à la racine est une copie du dernier build Release, pas une source.
- Vérifier un build : `lipo -archs Trigonometry.app/Contents/MacOS/Trigonometry` (attendu : `x86_64 arm64`) et `codesign -dv Trigonometry.app` (attendu : `flags=0x10002(adhoc,runtime)`).

## Icône

`trigo.icns` à la racine (référencée par `CFBundleIconFile = trigo`, pas de catalogue d'assets). Elle est produite par `Icon/make_icon.swift` :

```bash
swiftc Icon/make_icon.swift -o /tmp/make_icon && /tmp/make_icon Icon && iconutil -c icns Icon/trigo.iconset -o trigo.icns
```

Le script écrit `icon-1024.png` (aperçu, conservé dans `Icon/`) et `trigo.iconset` (intermédiaire, à supprimer après `iconutil`). Les traits sont épaissis de 50 % pour les rendus de 64 px et moins.

## Vérification

Il n'y a pas de tests. Lors de la modernisation, Claude n'avait accès ni à l'écran ni à l'accessibilité ; le rendu a été contrôlé hors écran par un harnais jetable : `swiftc TrigoModel.swift TrigoView.swift ContentView.swift main.swift`, où `main.swift` rend la vue dans un PNG (`NSHostingView` + `cacheDisplay`) et l'impression dans un PDF (`dataWithPDF` sur la vue de `makePrintView`). Ce harnais n'est pas dans le dossier ; le recréer dans un répertoire temporaire au besoin (ne pas inclure `TrigonometryApp.swift`, qui porte `@main`).

**Jamais testé par Claude** : le glisser à la souris dans la vraie fenêtre et le dialogue d'impression. Après une modification qui y touche, le dire et demander à l'auteur d'essayer.

## Archives : ne pas toucher

- `Trigonometry-1.3-original.zip` : projet d'origine complet de 2008.
- `Legacy/` : ancien projet Xcode 3, nibs Interface Builder 2, anciennes localisations, ancienne icône `trigo-2004.icns`, et `Legacy/ObjC-1.4/` (version Objective-C modernisée avec son propre `project.pbxproj`). Utile comme référence de comportement, pas comme code à maintenir.
