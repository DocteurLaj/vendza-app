# Vendza CI/CD

Chaque push sur `main` lance le workflow `.github/workflows/ci.yml` pour le
meme commit :

- analyse et tests Flutter ;
- APK et AAB Android signes, disponibles dans les artifacts GitHub pendant
  30 jours ;
- validation iOS non signee, disponible sous forme d'archive ;
- image Web Nginx publiee dans
  `ghcr.io/docteurlaj/vendza-app:latest`, puis deploiement Dokploy.

## Variables GitHub

Dans `Settings > Secrets and variables > Actions > Variables`, ajouter :

- `VENDZA_API_BASE_URL` : URL HTTPS terminee par `/api/v1` ;
- `VENDZA_MEDIA_BASE_URL` : URL HTTPS publique du bucket media ;
- `GOOGLE_WEB_CLIENT_ID` : client OAuth Web complet ;
- `GOOGLE_IOS_CLIENT_ID` : client OAuth iOS complet.

Les deux URL Vendza actuelles sont utilisees comme valeurs par defaut. Les
identifiants Google n'ont volontairement aucune valeur par defaut.

## Secrets Android

Dans `Settings > Secrets and variables > Actions > Secrets`, ajouter :

- `ANDROID_KEYSTORE_BASE64` ;
- `ANDROID_KEY_ALIAS` ;
- `ANDROID_KEY_PASSWORD` ;
- `ANDROID_STORE_PASSWORD`.

Pour encoder le keystore sous PowerShell :

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("android/app/upload-keystore.jks")
) | Set-Clipboard
```

Coller le resultat dans `ANDROID_KEYSTORE_BASE64`. Ne jamais committer le
keystore ou `android/key.properties`. Conserver une sauvegarde privee du
keystore : les futures mises a jour Android doivent employer la meme cle.

## Dokploy

Configurer l'application Dokploy avec l'image :

```text
ghcr.io/docteurlaj/vendza-app:latest
```

Le package GHCR est prive par defaut. Dokploy doit donc recevoir un identifiant
GitHub disposant de `read:packages`, ou le package doit etre rendu public.
Configurer le domaine Dokploy sur le port `8080` et le health check `/healthz`.

Ajouter ensuite ces secrets GitHub Actions :

- `DOKPLOY_URL` : origine de Dokploy, par exemple `https://deploy.example.com` ;
- `DOKPLOY_API_TOKEN` : token cree dans le profil Dokploy ;
- `DOKPLOY_APPLICATION_ID` : identifiant de l'application Web Dokploy.

Sans ces trois secrets, GitHub publie quand meme l'image Web mais ne demande
pas encore son deploiement.

## iOS

L'archive `vendza-ios-unsigned` valide que le code compile sur macOS, mais elle
n'est pas installable et ne peut pas etre envoyee sur l'App Store. Un fichier
IPA distribuable exige un compte Apple Developer, un certificat de
distribution et un provisioning profile. Ces elements pourront etre ajoutes
au workflow lorsque le compte Apple sera configure.
