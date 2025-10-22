# 🚀 QUICK START - Veille Stratégique Marocaine

Guide de démarrage rapide pour déployer la plateforme de veille stratégique.

---

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir :

- ✅ **Docker** et **Docker Compose** installés
- ✅ **Git** installé
- ✅ **SSH** configuré pour accéder au VPS
- ✅ Un **VPS** avec Ubuntu/Debian (minimum 2GB RAM)
- ✅ Les **fichiers sources** dans `~/Downloads/files/`

---

## 🎯 Déploiement en 4 étapes

### Étape 1 : Configuration locale

```bash
cd deployment-scripts
chmod +x *.sh
./setup-local.sh
```

**Ce script va :**
- ✅ Vérifier Docker/Docker Compose
- ✅ Créer la structure des répertoires
- ✅ Cloner/copier les fichiers du projet
- ✅ Créer le fichier `.env` avec vos credentials

**Informations demandées :**
- Adresse IP du VPS
- Mot de passe PostgreSQL
- Clé API OpenRouter
- Email administrateur
- Mot de passe Gmail (app password)

---

### Étape 2 : Validation

```bash
./validate.sh
```

**Ce script va :**
- ✅ Vérifier la présence des 17 fichiers requis
- ✅ Valider la syntaxe YAML/JSON/SQL
- ✅ Vérifier les Dockerfiles
- ✅ Contrôler le fichier `.env`
- ✅ Générer un rapport de validation

**Fichiers requis :**
- `docker-compose.yml`
- `database-init.sql`
- `backend-*` (server.js, package.json, Dockerfile)
- `frontend-*` (package.json, Dockerfile)
- `n8n-*` (collecte.json, analyse.json, notification.json)
- Documentation (README.md, ARCHITECTURE.md, API.md)
- Configuration (.env.example, nginx.conf, sources-rss.json)

---

### Étape 3 : Déploiement sur le VPS

```bash
./deploy-vps.sh
```

**Ce script va :**
- ✅ Se connecter au VPS via SSH
- ✅ Installer Docker/Docker Compose (si nécessaire)
- ✅ Créer `/opt/veille-maroc/`
- ✅ Transférer tous les fichiers (SCP)
- ✅ Lancer `docker-compose up -d`
- ✅ Configurer le pare-feu
- ✅ Tester les services

**Durée estimée :** 5-10 minutes

---

### Étape 4 : Tests des services

```bash
./test-services.sh
```

**Ce script va :**
- ✅ Tester PostgreSQL (connexion, version, tables)
- ✅ Tester N8N (accessibilité, API)
- ✅ Tester Backend (health check, routes)
- ✅ Tester Frontend (accessibilité, HTML)
- ✅ Vérifier la connectivité inter-services
- ✅ Insérer 3 clients test
- ✅ Générer un rapport HTML

**Rapport généré :** `test-report.html`

---

### Étape 5 (Optionnelle) : Configuration N8N

```bash
./setup-n8n.sh
```

**Ce script va vous guider pour :**
- ✅ Configurer l'authentification N8N
- ✅ Ajouter les credentials PostgreSQL
- ✅ Ajouter les credentials OpenRouter
- ✅ Importer les workflows (collecte, analyse, notification)
- ✅ Activer les schedules
- ✅ Tester les workflows

---

## 🎬 Déploiement en une commande (Make)

Si vous préférez utiliser Make :

```bash
make deploy
```

Ou étape par étape :

```bash
make setup      # Setup local
make validate   # Validation
make deploy-vps # Déploiement VPS
make test       # Tests
make n8n        # Configuration N8N
make report     # Voir le rapport
```

---

## 📊 Vérifier le déploiement

### Accéder aux services

```bash
# Frontend
http://YOUR_VPS_IP:3000

# Backend API
http://YOUR_VPS_IP:3001/api/health

# N8N
http://YOUR_VPS_IP:5678
```

### Voir les logs

```bash
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose logs -f'
```

### Vérifier le status

```bash
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose ps'
```

---

## 🛠️ Commandes utiles

### Gestion des services

```bash
# Redémarrer tous les services
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose restart'

# Arrêter tous les services
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose stop'

# Démarrer tous les services
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose up -d'

# Reconstruire et redémarrer
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose up -d --build'
```

### Logs par service

```bash
# Logs PostgreSQL
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose logs postgres --tail=100'

# Logs N8N
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose logs n8n --tail=100'

# Logs Backend
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose logs backend --tail=100'

# Logs Frontend
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose logs frontend --tail=100'
```

### Base de données

```bash
# Se connecter à PostgreSQL
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose exec postgres psql -U veille_user -d veille_maroc'

# Lister les tables
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose exec -T postgres psql -U veille_user -d veille_maroc -c "\dt"'

# Compter les articles
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose exec -T postgres psql -U veille_user -d veille_maroc -c "SELECT COUNT(*) FROM articles;"'
```

---

## 🔧 Troubleshooting

### Problème : Docker n'est pas installé

```bash
# Installation sur Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Installation Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Problème : Connexion SSH échoue

```bash
# Vérifier que SSH fonctionne
ssh root@YOUR_VPS_IP 'echo "SSH OK"'

# Générer une clé SSH (si nécessaire)
ssh-keygen -t rsa -b 4096

# Copier la clé sur le VPS
ssh-copy-id root@YOUR_VPS_IP
```

### Problème : Un service ne démarre pas

```bash
# Voir les logs du service
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose logs SERVICE_NAME'

# Redémarrer le service
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose restart SERVICE_NAME'

# Reconstruire le service
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose up -d --build SERVICE_NAME'
```

### Problème : PostgreSQL refuse les connexions

```bash
# Vérifier que PostgreSQL est démarré
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose ps postgres'

# Tester la connexion
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose exec postgres pg_isready -U veille_user'

# Vérifier les credentials dans .env
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && cat .env | grep POSTGRES'
```

### Problème : N8N ne collecte pas

1. Vérifiez les credentials dans N8N
2. Testez le workflow manuellement
3. Vérifiez les logs : `docker-compose logs n8n`
4. Assurez-vous que le workflow est ACTIF

### Problème : Port déjà utilisé

```bash
# Voir les ports utilisés
ssh root@YOUR_VPS_IP 'netstat -tulpn | grep LISTEN'

# Modifier les ports dans docker-compose.yml si nécessaire
# Par exemple : "8000:3000" au lieu de "3000:3000"
```

---

## 📐 Architecture

```
┌─────────────────────────────────────────────────────────┐
│              VEILLE STRATÉGIQUE MAROC                    │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────┐          ┌──────────────┐              │
│  │  Frontend   │◄────────►│  Backend API │              │
│  │  (React)    │          │  (Node.js)   │              │
│  │  :3000      │          │  :3001       │              │
│  └─────────────┘          └──────┬───────┘              │
│                                   │                      │
│                                   ▼                      │
│                          ┌─────────────────┐             │
│                          │   PostgreSQL    │             │
│                          │     :5432       │             │
│                          └────────▲────────┘             │
│                                   │                      │
│  ┌────────────────────────────────┴────────────────┐    │
│  │              N8N Automation (:5678)             │    │
│  ├─────────────────────────────────────────────────┤    │
│  │  1. Collecte RSS  (*/2h)                        │    │
│  │  2. Analyse IA    (*/1h) → OpenRouter           │    │
│  │  3. Notification  (daily) → Email               │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

---

## 📚 Documentation complète

- **Architecture détaillée :** `ARCHITECTURE.md`
- **Documentation API :** `API.md`
- **README principal :** `README.md`
- **Rapport de déploiement :** `report.html`

---

## 🎯 Prochaines étapes

Après le déploiement :

1. ✅ Changez les mots de passe par défaut
2. ✅ Configurez les sources RSS dans `sources-rss.json`
3. ✅ Ajoutez des clients dans la base de données
4. ✅ Testez la collecte et l'analyse
5. ✅ Configurez les notifications email
6. ✅ Sécurisez avec HTTPS (Let's Encrypt)
7. ✅ Mettez en place les backups automatiques

---

## 🔒 Sécurité

### Changez immédiatement :

```bash
# Dans .env
N8N_BASIC_AUTH_PASSWORD=votre-mot-de-passe-fort
POSTGRES_PASSWORD=votre-mot-de-passe-fort
JWT_SECRET=$(openssl rand -base64 32)
SESSION_SECRET=$(openssl rand -base64 32)
```

### Configurez HTTPS avec Let's Encrypt :

```bash
# Installer Certbot
sudo apt install certbot python3-certbot-nginx

# Obtenir un certificat
sudo certbot --nginx -d votre-domaine.com
```

### Configurez le pare-feu :

```bash
# UFW (Ubuntu)
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# Fermez les ports de dev si en production
# Ne laissez que 80/443 ouverts
```

---

## 📊 Monitoring

### Avec Docker stats

```bash
ssh root@YOUR_VPS_IP 'docker stats'
```

### Vérification de santé

```bash
# Backend health check
curl http://YOUR_VPS_IP:3001/api/health

# Test de toutes les URLs
curl -I http://YOUR_VPS_IP:3000
curl -I http://YOUR_VPS_IP:3001
curl -I http://YOUR_VPS_IP:5678
```

---

## 💾 Backups

### Script de backup PostgreSQL

```bash
#!/bin/bash
# backup-postgres.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/veille-maroc/backups"

mkdir -p $BACKUP_DIR

docker-compose exec -T postgres pg_dump -U veille_user veille_maroc > $BACKUP_DIR/veille_maroc_$DATE.sql

# Garder seulement les 7 derniers backups
ls -t $BACKUP_DIR/veille_maroc_*.sql | tail -n +8 | xargs rm -f

echo "Backup créé: veille_maroc_$DATE.sql"
```

### Planifier avec cron

```bash
# Éditer crontab
crontab -e

# Ajouter (backup tous les jours à 2h)
0 2 * * * /opt/veille-maroc/backup-postgres.sh
```

---

## 🆘 Support

En cas de problème :

1. Vérifiez les logs : `./logs/deployment.log`
2. Relancez la validation : `./validate.sh`
3. Consultez les logs Docker : `docker-compose logs`
4. Relancez les tests : `./test-services.sh`

---

## 📞 Contact

Pour toute question sur le déploiement, consultez :

- 📖 La documentation complète dans `docs/`
- 🐛 Les logs dans `logs/`
- 📊 Le rapport HTML : `report.html`

---

## ✅ Checklist de déploiement

- [ ] Setup local exécuté
- [ ] Validation passée avec succès
- [ ] Déploiement VPS réussi
- [ ] Tous les tests passent
- [ ] N8N configuré et workflows actifs
- [ ] Credentials changés
- [ ] HTTPS configuré (production)
- [ ] Backups configurés
- [ ] Monitoring en place
- [ ] Documentation à jour

---

🎉 **Félicitations ! Votre plateforme de veille est maintenant opérationnelle !**
