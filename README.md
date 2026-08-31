# Vendza App

Application Flutter autonome de Vendza Marketplace pour Android, iOS et Web.
Le backend n'est pas inclus dans ce depot.

## Prerequis

- Flutter `3.44.2` (stable)
- Dart `3.12.2`
- Docker avec Compose pour valider l'image Web

## Developpement local

```powershell
flutter pub get
flutter run --dart-define=VENDZA_API_BASE_URL=http://10.0.2.2:8000/api/v1
```

En debug Android, l'URL API utilise par defaut
`http://10.0.2.2:8000/api/v1`. Une release exige une URL HTTPS publique.

## Build Web

Les valeurs Flutter sont integrees au moment du build. Elles ne peuvent pas
etre remplacees au demarrage du conteneur.

```powershell
flutter build web --release `
  --dart-define=VENDZA_API_BASE_URL=https://api.example.com/api/v1 `
  --dart-define=GOOGLE_WEB_CLIENT_ID=000000000000-example.apps.googleusercontent.com
```

`VENDZA_API_BASE_URL` est obligatoire en release et doit inclure `/api/v1`.
`GOOGLE_WEB_CLIENT_ID` est optionnel : sans lui, l'interface Google Sign-In est
masquee. Un identifiant OAuth est public par conception, mais aucun secret OAuth
ne doit etre ajoute a Flutter.

## Docker et Dokploy

Copier les noms de variables de `.env.dokploy.example` dans la configuration de
build Dokploy, avec les vraies valeurs publiques. Dokploy peut construire le
`Dockerfile` directement ou utiliser `compose.yaml`. Le conteneur ecoute sur le
port `8081`, expose `/healthz`, sert les fichiers statiques avec Nginx et renvoie
les routes inconnues vers `index.html` pour la navigation SPA.

Validation locale :

```powershell
$env:VENDZA_API_BASE_URL='https://api.example.com/api/v1'
docker compose build
docker compose up -d
```

## Domaines et CORS

Pour un domaine Web `https://app.example.com` :

- router ce domaine Dokploy vers le port `8081` du service Web ;
- ajouter exactement `https://app.example.com` aux origines CORS autorisees du backend ;
- autoriser cette meme origine sur le stockage objet si le navigateur envoie directement des fichiers via des URLs presignees ;
- ajouter cette origine aux origines JavaScript autorisees du client OAuth Google Web ;
- utiliser une API HTTPS, par exemple `https://api.example.com/api/v1`.

Le CORS est une politique emise par l'API ou le stockage : aucune configuration
Flutter ne peut remplacer ces en-tetes serveur.

## Google Sign-In

- Web et backend : `GOOGLE_WEB_CLIENT_ID`
- iOS : `GOOGLE_IOS_CLIENT_ID`
- Android : client OAuth lie au package `app.vendza.marketplace` et aux empreintes SHA

Les fichiers `google-services.json`, `GoogleService-Info.plist`, les secrets OAuth,
keystores et fichiers de signature sont exclus du depot.

## Validation

```powershell
flutter analyze
flutter test
flutter build web --release --dart-define=VENDZA_API_BASE_URL=https://api.example.com/api/v1
```

## Builds automatiques

GitHub Actions produit les APK/AAB Android, valide iOS et publie l'image Web
utilisee par Dokploy a chaque push sur `main`. La configuration des variables,
des signatures et de Dokploy est decrite dans [CI_CD.md](CI_CD.md).
