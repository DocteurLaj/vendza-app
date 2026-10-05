# Release web immutable par digest

## Objectif

Le Web doit être déployé avec une référence OCI immuable :

```text
ghcr.io/docteurlaj/vendza-app@sha256:<digest>
```

Le tag `latest` ne doit jamais être la référence active de Dokploy ou de Docker Swarm.

## Flux retenu

1. GitHub Actions récupère le ref demandé.
2. Les validations Flutter passent avant le release workflow.
3. Le Dockerfile est construit avec les build args Web publics nécessaires.
4. L’image est publiée avec le SHA Git comme tag technique.
5. Le digest OCI retourné par Buildx est récupéré.
6. Dokploy est configuré avec `application.saveDockerProvider` et la référence `image@sha256:digest`.
7. Dokploy est déclenché avec `application.deploy`.
8. La release est acceptée uniquement après vérification indépendante de Dokploy, Swarm, de l’image active et du HTTPS public.

Le workflow de transition est `.github/workflows/immutable-web-release.yml`. Il est manuel et doit être utilisé d’abord avec l’application staging. Le workflow CI historique qui publie GHCR `latest` reste intact jusqu’à la validation complète du nouveau flux.

## Preuve obligatoire pour chaque release

Conserver :

- SHA Git exact ;
- deployment ID Dokploy ;
- référence image complète avec digest ;
- résultat de `docker service inspect` ;
- tâche `Running` de `docker service ps --no-trunc` ;
- healthcheck local ;
- réponse HTTPS publique ;
- parcours critique : chargement, API, authentification.

## Test staging A/B

Avant production :

1. déployer le commit A et enregistrer son digest ;
2. déployer un commit B distinct et enregistrer son digest ;
3. vérifier que Swarm sert le digest B ;
4. restaurer le digest A via `application.saveDockerProvider` puis `application.deploy` ;
5. vérifier que Swarm sert exactement le digest A ;
6. vérifier `/healthz`, HTTPS et authentification après le rollback.

Une reconstruction du même commit peut produire un digest différent. Pour cette raison, le rollback ne reconstruit jamais le code : il réutilise le digest OCI original conservé dans le dossier de release.

Le workflow `.github/workflows/immutable-web-rollback.yml` configure et déploie directement la référence `image@sha256:digest` fournie. Il vérifie que Dokploy a enregistré cette référence avant de lancer le déploiement.

## Migration production

La production ne doit être modifiée qu’après le test A/B staging. Avant le premier déploiement production :

- sauvegarder le digest actuellement actif ;
- vérifier que ce digest est toujours disponible dans GHCR ;
- configurer une protection GitHub pour l’environnement `production` ;
- exécuter le workflow avec l’application production ;
- vérifier Dokploy, Swarm, healthcheck, HTTPS et authentification ;
- conserver l’ancien digest pendant toute la fenêtre de stabilisation.
