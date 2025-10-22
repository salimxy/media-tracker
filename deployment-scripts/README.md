# 🚀 Scripts de Déploiement - Veille Stratégique Marocaine

> Automatisation complète du déploiement de la plateforme de veille stratégique marocaine

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)](https://www.docker.com/)

---

## 📋 Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Prérequis](#prérequis)
- [Installation rapide](#installation-rapide)
- [Scripts disponibles](#scripts-disponibles)
- [Utilisation](#utilisation)
- [Makefile](#makefile)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Vue d'ensemble

Ce répertoire contient une suite complète de scripts Bash pour automatiser le déploiement de la plateforme de veille stratégique marocaine sur un VPS.

### Fonctionnalités

- ✅ **Setup automatisé** - Configuration locale en une commande
- ✅ **Validation complète** - Vérification de tous les fichiers (YAML, JSON, SQL, Docker)
- ✅ **Déploiement VPS** - Transfert et démarrage automatique via SSH/SCP
- ✅ **Tests intégrés** - Suite de tests pour chaque service
- ✅ **Configuration N8N** - Setup guidé des workflows d'automatisation
- ✅ **Rapports HTML** - Visualisation élégante des résultats
- ✅ **Makefile** - Commandes simplifiées pour toutes les opérations

### Architecture déployée

```
┌─────────────────────────────────────────────────┐
│         Veille Stratégique Marocaine            │
├─────────────────────────────────────────────────┤
│  Frontend (React) :3000                         │
│  Backend API (Node.js) :3001                    │
│  N8N Automation :5678                           │
│  PostgreSQL :5432                               │
└─────────────────────────────────────────────────┘
```

---

## 🔧 Prérequis

### Sur votre machine locale

- **Docker** >= 20.10
- **Docker Compose** >= 1.29
- **Git** >= 2.0
- **SSH** client
- **curl** pour les tests
- **Bash** >= 4.0

### Sur le VPS

- **Ubuntu 20.04+** ou **Debian 10+**
- **2GB RAM** minimum (4GB recommandé)
- **20GB stockage** minimum
- **Accès root** via SSH
- **Ports ouverts**: 22, 80, 443, 3000, 3001, 5678

### Credentials requis

- 🔑 **Clé API OpenRouter** - Pour l'analyse IA
- 📧 **Email Gmail + App Password** - Pour les notifications
- 🌍 **IP du VPS** - Adresse de votre serveur
- 🔐 **Accès SSH** - Clé SSH configurée

---

## ⚡ Installation rapide

### Méthode 1 : Déploiement automatique complet

```bash
cd deployment-scripts
make all
```

Cette commande exécute automatiquement :
1. Setup local
2. Validation
3. Déploiement VPS
4. Tests des services

### Méthode 2 : Étape par étape

```bash
# 1. Setup local
./setup-local.sh

# 2. Validation
./validate.sh

# 3. Déploiement VPS
./deploy-vps.sh

# 4. Tests
./test-services.sh

# 5. Configuration N8N (optionnel)
./setup-n8n.sh
```

### Méthode 3 : Avec Make (recommandé)

```bash
# Afficher l'aide
make help

# Déploiement complet
make deploy

# Ou étape par étape
make setup
make validate
make deploy-vps
make test
make n8n
```

---

## 📜 Scripts disponibles

### 1. `setup-local.sh` - Configuration locale

**Fonction :** Prépare l'environnement local pour le déploiement

**Actions :**
- ✅ Vérifie Docker, Docker Compose, Git, SSH
- ✅ Clone/copie le repository
- ✅ Crée la structure des répertoires
- ✅ Valide la présence des 17 fichiers requis
- ✅ Crée le fichier `.env` avec vos credentials

**Usage :**
```bash
./setup-local.sh
```

**Durée :** ~2-3 minutes

---

### 2. `validate.sh` - Validation des fichiers

**Fonction :** Valide tous les fichiers avant déploiement

**Validations :**
- ✅ Existence des 17 fichiers requis
- ✅ Syntaxe YAML (docker-compose.yml)
- ✅ Syntaxe JSON (package.json, n8n workflows, sources-rss.json)
- ✅ Syntaxe SQL (database-init.sql)
- ✅ Dockerfiles (instructions FROM, WORKDIR)
- ✅ Fichier .env (variables requises)
- ✅ Structure des répertoires

**Rapport :** `validation-report.txt`

**Usage :**
```bash
./validate.sh
```

**Code de sortie :**
- `0` : Toutes les validations ont réussi
- `1` : Au moins une validation a échoué

---

### 3. `deploy-vps.sh` - Déploiement sur le VPS

**Fonction :** Déploie l'application sur le serveur VPS

**Actions :**
- ✅ Teste la connexion SSH au VPS
- ✅ Installe Docker/Docker Compose (si nécessaire)
- ✅ Crée `/opt/veille-maroc/` sur le VPS
- ✅ Transfère tous les fichiers (SCP avec retry)
- ✅ Configure le fichier `.env` pour le VPS
- ✅ Lance `docker-compose up -d --build`
- ✅ Attend le démarrage des services (30s)
- ✅ Effectue des tests rapides
- ✅ Configure le pare-feu (UFW/Firewalld)

**Usage :**
```bash
./deploy-vps.sh
```

**Durée :** ~5-10 minutes (dépend de la vitesse réseau)

**Retry :** 3 tentatives automatiques en cas d'erreur réseau

---

### 4. `test-services.sh` - Tests des services

**Fonction :** Teste tous les services déployés

**Tests effectués :**

**PostgreSQL :**
- ✅ Connexion (`pg_isready`)
- ✅ Version
- ✅ Présence des tables
- ✅ Insertion de données test

**N8N :**
- ✅ Accessibilité HTTP
- ✅ API health check
- ✅ Logs de démarrage

**Backend API :**
- ✅ Accessibilité HTTP
- ✅ Endpoint `/api/health`
- ✅ Routes API disponibles
- ✅ Absence d'erreurs dans les logs

**Frontend :**
- ✅ Accessibilité HTTP
- ✅ Contenu HTML valide
- ✅ Ressources statiques
- ✅ Absence d'erreurs dans les logs

**Tests supplémentaires :**
- ✅ Connectivité inter-services
- ✅ Insertion de 3 clients test
- ✅ Tests de performance (temps de réponse)

**Rapports générés :**
- `test-report.html` - Rapport HTML interactif
- `logs/tests.log` - Logs détaillés

**Usage :**
```bash
./test-services.sh
```

**Durée :** ~3-5 minutes

---

### 5. `setup-n8n.sh` - Configuration N8N

**Fonction :** Configure N8N et importe les workflows

**Configuration guidée :**
- ✅ Authentification N8N
- ✅ Credentials PostgreSQL
- ✅ Credentials OpenRouter API
- ✅ Import des workflows :
  - Collecte RSS (schedule: toutes les 2h)
  - Analyse IA (schedule: toutes les heures)
  - Notifications email (schedule: quotidien)
- ✅ Activation des workflows
- ✅ Configuration des webhooks (optionnel)
- ✅ Backup de la configuration

**Usage :**
```bash
./setup-n8n.sh
```

**Mode :** Interactif (attend les confirmations utilisateur)

**Durée :** ~10-15 minutes

---

## 🎮 Makefile

Le Makefile fournit des commandes simplifiées pour toutes les opérations.

### Commandes principales

```bash
make help           # Affiche l'aide complète
make all           # Déploiement complet (setup → validate → deploy → test)
make deploy        # Alias pour 'make all'
```

### Commandes par étape

```bash
make setup         # Setup local
make validate      # Validation
make deploy-vps    # Déploiement VPS
make test          # Tests
make n8n           # Configuration N8N
```

### Monitoring

```bash
make status        # Statut des services
make logs          # Voir les logs (50 dernières lignes)
make logs-follow   # Suivre les logs en temps réel
make logs-backend  # Logs du Backend
make logs-frontend # Logs du Frontend
make logs-n8n      # Logs de N8N
make logs-postgres # Logs de PostgreSQL
```

### Contrôle des services

```bash
make restart       # Redémarrer tous les services
make stop          # Arrêter tous les services
make start         # Démarrer tous les services
make rebuild       # Reconstruire et redémarrer
```

### Base de données

```bash
make db-connect    # Se connecter à PostgreSQL
make db-tables     # Lister les tables
make db-backup     # Créer un backup
make db-restore FILE=backup.sql  # Restaurer
```

### Tests rapides

```bash
make test-postgres  # Tester PostgreSQL uniquement
make test-backend   # Tester Backend uniquement
make test-frontend  # Tester Frontend uniquement
make test-n8n       # Tester N8N uniquement
make test-all-services  # Tous les tests rapides
```

### Rapports

```bash
make report              # Ouvrir report.html
make validation-report   # Afficher rapport de validation
make test-report         # Ouvrir test-report.html
```

### Utilitaires

```bash
make urls          # Afficher toutes les URLs d'accès
make info          # Informations sur le déploiement
make ssh           # Se connecter au VPS
make clean         # Nettoyer les fichiers temporaires
make docs          # Ouvrir la documentation
make version       # Afficher les versions
```

---

## 📚 Documentation

| Fichier | Description |
|---------|-------------|
| **QUICK-START.md** | Guide de démarrage rapide |
| **report.html** | Rapport de déploiement interactif |
| **test-report.html** | Rapport de tests détaillé |
| **validation-report.txt** | Résultats de validation |
| **logs/** | Logs détaillés de toutes les opérations |

---

## 🔍 Structure des fichiers

```
deployment-scripts/
├── setup-local.sh           # Setup local
├── validate.sh              # Validation
├── deploy-vps.sh            # Déploiement VPS
├── test-services.sh         # Tests
├── setup-n8n.sh             # Configuration N8N
├── Makefile                 # Commandes Make
├── README.md                # Ce fichier
├── QUICK-START.md           # Guide rapide
├── report.html              # Rapport HTML
├── logs/                    # Logs
│   ├── deployment.log
│   ├── validation.log
│   ├── tests.log
│   └── n8n-setup.log
└── veille-maroc/            # Projet (créé par setup)
    ├── .env
    ├── docker-compose.yml
    ├── backend/
    ├── frontend/
    ├── n8n/
    └── database/
```

---

## 🛠️ Troubleshooting

### Problème : SSH échoue

```bash
# Vérifier la connexion
ssh root@YOUR_VPS_IP 'echo OK'

# Copier votre clé SSH
ssh-copy-id root@YOUR_VPS_IP
```

### Problème : Docker non installé sur le VPS

Le script `deploy-vps.sh` installe automatiquement Docker. Si l'installation échoue :

```bash
# Connexion SSH manuelle
ssh root@YOUR_VPS_IP

# Installation manuelle
curl -fsSL https://get.docker.com | sh
```

### Problème : Un service ne démarre pas

```bash
# Voir les logs
make logs-[service]

# Exemple
make logs-backend

# Redémarrer le service
ssh root@YOUR_VPS_IP 'cd /opt/veille-maroc && docker-compose restart backend'
```

### Problème : Validation échoue

```bash
# Voir le rapport détaillé
cat validation-report.txt

# Ou relancer avec plus de détails
./validate.sh 2>&1 | tee validation-debug.log
```

### Problème : N8N ne collecte pas

1. Vérifiez que les workflows sont actifs (toggle vert)
2. Vérifiez les credentials dans N8N
3. Testez manuellement : cliquez sur "Execute Workflow"
4. Consultez les logs : `make logs-n8n`

---

## 🔐 Sécurité

### Avant de passer en production :

1. **Changez tous les mots de passe**
   ```bash
   # Éditez .env
   nano veille-maroc/.env
   ```

2. **Configurez HTTPS**
   ```bash
   # Installez Certbot
   ssh root@YOUR_VPS_IP 'apt install certbot python3-certbot-nginx'

   # Obtenez un certificat
   ssh root@YOUR_VPS_IP 'certbot --nginx -d votre-domaine.com'
   ```

3. **Fermez les ports inutiles**
   ```bash
   # Gardez seulement 22 (SSH), 80 (HTTP), 443 (HTTPS)
   ssh root@YOUR_VPS_IP 'ufw allow 22 && ufw allow 80 && ufw allow 443 && ufw enable'
   ```

4. **Activez les backups automatiques**
   ```bash
   # Ajoutez à crontab
   ssh root@YOUR_VPS_IP 'crontab -e'

   # Ajoutez : 0 2 * * * /opt/veille-maroc/backup.sh
   ```

---

## 📞 Support

En cas de problème :

1. ✅ Consultez les logs : `logs/deployment.log`
2. ✅ Relancez la validation : `make validate`
3. ✅ Vérifiez le rapport : `make report`
4. ✅ Consultez QUICK-START.md

---

## 🎉 Félicitations !

Votre plateforme de veille stratégique est maintenant déployée !

**Prochaines étapes :**
1. Accédez à N8N : http://YOUR_VPS_IP:5678
2. Activez les workflows de collecte
3. Consultez le Frontend : http://YOUR_VPS_IP:3000
4. Configurez vos sources RSS personnalisées

---

## 📄 Licence

MIT License - Libre d'utilisation et de modification

---

**Version :** 1.0.0
**Date :** Octobre 2024
**Auteur :** Scripts d'automatisation pour Veille Stratégique Marocaine
