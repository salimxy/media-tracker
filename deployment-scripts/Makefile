# ============================================================================
# 🚀 MAKEFILE - Veille Stratégique Marocaine
# Automatisation du déploiement et de la gestion
# ============================================================================

.PHONY: help setup validate deploy-vps test n8n report clean logs status restart all

# Couleurs pour l'affichage
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

# Configuration
SCRIPTS_DIR := .
PROJECT_DIR := ./veille-maroc
LOGS_DIR := ./logs

# Variables d'environnement
-include $(PROJECT_DIR)/.env
export

# ============================================================================
# AIDE
# ============================================================================

help: ## Affiche cette aide
	@echo "$(BLUE)╔═══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║        VEILLE STRATÉGIQUE MAROCAINE - DEPLOYMENT             ║$(NC)"
	@echo "$(BLUE)╚═══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)📋 Commandes disponibles:$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)🎯 Déploiement complet:$(NC)"
	@echo "  $(YELLOW)make all$(NC)             Lance toutes les étapes automatiquement"
	@echo ""
	@echo "$(GREEN)📊 Monitoring:$(NC)"
	@echo "  $(YELLOW)make status$(NC)          Statut des services"
	@echo "  $(YELLOW)make logs$(NC)            Voir les logs"
	@echo ""

# ============================================================================
# DÉPLOIEMENT PRINCIPAL
# ============================================================================

all: setup validate deploy-vps test report ## 🚀 Déploiement complet (setup → validate → deploy → test → report)
	@echo "$(GREEN)✅ Déploiement complet terminé!$(NC)"
	@echo ""
	@echo "$(YELLOW)🎯 Prochaines étapes:$(NC)"
	@echo "  1. Configurez N8N: make n8n"
	@echo "  2. Consultez le rapport: make report"
	@echo ""

deploy: all ## Alias pour 'make all'

# ============================================================================
# ÉTAPES INDIVIDUELLES
# ============================================================================

setup: ## 🔧 Setup local (étape 1)
	@echo "$(BLUE)═══════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)  Étape 1/4: Setup Local$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════$(NC)"
	@chmod +x $(SCRIPTS_DIR)/setup-local.sh
	@$(SCRIPTS_DIR)/setup-local.sh
	@echo "$(GREEN)✅ Setup terminé$(NC)"
	@echo ""

validate: ## ✅ Validation des fichiers (étape 2)
	@echo "$(BLUE)═══════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)  Étape 2/4: Validation$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════$(NC)"
	@chmod +x $(SCRIPTS_DIR)/validate.sh
	@$(SCRIPTS_DIR)/validate.sh
	@echo "$(GREEN)✅ Validation terminée$(NC)"
	@echo ""

deploy-vps: ## 🚀 Déploiement sur le VPS (étape 3)
	@echo "$(BLUE)═══════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)  Étape 3/4: Déploiement VPS$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════$(NC)"
	@chmod +x $(SCRIPTS_DIR)/deploy-vps.sh
	@$(SCRIPTS_DIR)/deploy-vps.sh
	@echo "$(GREEN)✅ Déploiement VPS terminé$(NC)"
	@echo ""

test: ## 🧪 Tests des services (étape 4)
	@echo "$(BLUE)═══════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)  Étape 4/4: Tests$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════$(NC)"
	@chmod +x $(SCRIPTS_DIR)/test-services.sh
	@$(SCRIPTS_DIR)/test-services.sh
	@echo "$(GREEN)✅ Tests terminés$(NC)"
	@echo ""

n8n: ## 🔄 Configuration N8N (étape 5 optionnelle)
	@echo "$(BLUE)═══════════════════════════════════════════════════$(NC)"
	@echo "$(BLUE)  Configuration N8N$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════$(NC)"
	@chmod +x $(SCRIPTS_DIR)/setup-n8n.sh
	@$(SCRIPTS_DIR)/setup-n8n.sh
	@echo "$(GREEN)✅ N8N configuré$(NC)"
	@echo ""

# ============================================================================
# RAPPORTS
# ============================================================================

report: ## 📊 Ouvrir le rapport HTML
	@echo "$(GREEN)📊 Ouverture du rapport...$(NC)"
	@if [ -f "$(SCRIPTS_DIR)/report.html" ]; then \
		xdg-open $(SCRIPTS_DIR)/report.html 2>/dev/null || open $(SCRIPTS_DIR)/report.html 2>/dev/null || echo "$(YELLOW)Ouvrez manuellement: $(SCRIPTS_DIR)/report.html$(NC)"; \
	else \
		echo "$(RED)❌ Rapport non trouvé. Exécutez d'abord: make test$(NC)"; \
	fi

validation-report: ## 📋 Afficher le rapport de validation
	@if [ -f "$(SCRIPTS_DIR)/validation-report.txt" ]; then \
		cat $(SCRIPTS_DIR)/validation-report.txt; \
	else \
		echo "$(RED)❌ Rapport de validation non trouvé. Exécutez: make validate$(NC)"; \
	fi

test-report: ## 🧪 Ouvrir le rapport de tests
	@if [ -f "$(SCRIPTS_DIR)/test-report.html" ]; then \
		xdg-open $(SCRIPTS_DIR)/test-report.html 2>/dev/null || open $(SCRIPTS_DIR)/test-report.html 2>/dev/null || echo "$(YELLOW)Ouvrez manuellement: $(SCRIPTS_DIR)/test-report.html$(NC)"; \
	else \
		echo "$(RED)❌ Rapport de tests non trouvé. Exécutez: make test$(NC)"; \
	fi

# ============================================================================
# MONITORING ET GESTION
# ============================================================================

status: ## 📊 Statut des services sur le VPS
	@echo "$(GREEN)📊 Statut des services...$(NC)"
	@if [ -z "$(VPS_IP)" ]; then \
		echo "$(RED)❌ VPS_IP non défini. Exécutez d'abord: make setup$(NC)"; \
		exit 1; \
	fi
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose ps'

logs: ## 📝 Voir les logs des services
	@echo "$(GREEN)📝 Logs des services...$(NC)"
	@if [ -z "$(VPS_IP)" ]; then \
		echo "$(RED)❌ VPS_IP non défini. Exécutez d'abord: make setup$(NC)"; \
		exit 1; \
	fi
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose logs --tail=50'

logs-follow: ## 📝 Suivre les logs en temps réel
	@echo "$(GREEN)📝 Suivi des logs en temps réel...$(NC)"
	@echo "$(YELLOW)Appuyez sur Ctrl+C pour quitter$(NC)"
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose logs -f'

logs-backend: ## 📝 Logs du Backend
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose logs backend --tail=50'

logs-frontend: ## 📝 Logs du Frontend
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose logs frontend --tail=50'

logs-n8n: ## 📝 Logs de N8N
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose logs n8n --tail=50'

logs-postgres: ## 📝 Logs de PostgreSQL
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose logs postgres --tail=50'

# ============================================================================
# CONTRÔLE DES SERVICES
# ============================================================================

restart: ## 🔄 Redémarrer tous les services
	@echo "$(YELLOW)🔄 Redémarrage des services...$(NC)"
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose restart'
	@echo "$(GREEN)✅ Services redémarrés$(NC)"

stop: ## ⏹️  Arrêter tous les services
	@echo "$(YELLOW)⏹️  Arrêt des services...$(NC)"
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose stop'
	@echo "$(GREEN)✅ Services arrêtés$(NC)"

start: ## ▶️  Démarrer tous les services
	@echo "$(GREEN)▶️  Démarrage des services...$(NC)"
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose up -d'
	@echo "$(GREEN)✅ Services démarrés$(NC)"

rebuild: ## 🔨 Reconstruire et redémarrer tous les services
	@echo "$(YELLOW)🔨 Reconstruction des services...$(NC)"
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose up -d --build'
	@echo "$(GREEN)✅ Services reconstruits et redémarrés$(NC)"

# ============================================================================
# BASE DE DONNÉES
# ============================================================================

db-connect: ## 🗄️  Se connecter à PostgreSQL
	@echo "$(GREEN)🗄️  Connexion à PostgreSQL...$(NC)"
	@ssh -t $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose exec postgres psql -U veille_user -d veille_maroc'

db-tables: ## 📋 Lister les tables
	@echo "$(GREEN)📋 Tables de la base de données:$(NC)"
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose exec -T postgres psql -U veille_user -d veille_maroc -c "\dt"'

db-backup: ## 💾 Backup de la base de données
	@echo "$(GREEN)💾 Création du backup...$(NC)"
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && mkdir -p backups && docker-compose exec -T postgres pg_dump -U veille_user veille_maroc > backups/veille_maroc_$$(date +%Y%m%d_%H%M%S).sql'
	@echo "$(GREEN)✅ Backup créé$(NC)"

db-restore: ## ♻️  Restaurer la base de données (usage: make db-restore FILE=backup.sql)
	@if [ -z "$(FILE)" ]; then \
		echo "$(RED)❌ Spécifiez le fichier: make db-restore FILE=backup.sql$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)⚠️  Restauration de la base de données...$(NC)"
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && cat $(FILE) | docker-compose exec -T postgres psql -U veille_user -d veille_maroc'
	@echo "$(GREEN)✅ Base restaurée$(NC)"

# ============================================================================
# TESTS ET VÉRIFICATIONS
# ============================================================================

test-postgres: ## 🧪 Tester PostgreSQL
	@echo "$(GREEN)🧪 Test PostgreSQL...$(NC)"
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose exec postgres pg_isready -U veille_user'

test-backend: ## 🧪 Tester Backend API
	@echo "$(GREEN)🧪 Test Backend API...$(NC)"
	@curl -s http://$(VPS_IP):3001/api/health || echo "$(RED)❌ Backend non accessible$(NC)"

test-frontend: ## 🧪 Tester Frontend
	@echo "$(GREEN)🧪 Test Frontend...$(NC)"
	@curl -s -o /dev/null -w "%{http_code}" http://$(VPS_IP):3000 || echo "$(RED)❌ Frontend non accessible$(NC)"

test-n8n: ## 🧪 Tester N8N
	@echo "$(GREEN)🧪 Test N8N...$(NC)"
	@curl -s -o /dev/null -w "%{http_code}" http://$(VPS_IP):5678 || echo "$(RED)❌ N8N non accessible$(NC)"

test-all-services: test-postgres test-backend test-frontend test-n8n ## 🧪 Tester tous les services rapidement

# ============================================================================
# UTILITAIRES
# ============================================================================

clean: ## 🧹 Nettoyer les fichiers temporaires
	@echo "$(YELLOW)🧹 Nettoyage...$(NC)"
	@rm -f $(LOGS_DIR)/*.log
	@rm -f validation-report.txt
	@rm -f test-report.html
	@echo "$(GREEN)✅ Nettoyage terminé$(NC)"

ssh: ## 🔌 Se connecter au VPS en SSH
	@ssh $(VPS_USER)@$(VPS_IP)

urls: ## 🌐 Afficher toutes les URLs d'accès
	@echo "$(BLUE)╔═══════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║           URLs D'ACCÈS                            ║$(NC)"
	@echo "$(BLUE)╚═══════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)🌐 Frontend:$(NC)    http://$(VPS_IP):3000"
	@echo "$(GREEN)🔌 Backend:$(NC)     http://$(VPS_IP):3001"
	@echo "$(GREEN)🔄 N8N:$(NC)         http://$(VPS_IP):5678"
	@echo "$(GREEN)🗄️  PostgreSQL:$(NC) $(VPS_IP):5432"
	@echo ""

info: ## ℹ️  Informations sur le déploiement
	@echo "$(BLUE)╔═══════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║        INFORMATIONS DE DÉPLOIEMENT                ║$(NC)"
	@echo "$(BLUE)╚═══════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)📍 VPS:$(NC)         $(VPS_IP)"
	@echo "$(GREEN)👤 Utilisateur:$(NC) $(VPS_USER)"
	@echo "$(GREEN)📁 Répertoire:$(NC)  /opt/veille-maroc"
	@echo "$(GREEN)🗄️  Database:$(NC)   $(POSTGRES_DB)"
	@echo ""
	@echo "$(YELLOW)📊 Commandes utiles:$(NC)"
	@echo "  make status      - Voir le statut"
	@echo "  make logs        - Voir les logs"
	@echo "  make restart     - Redémarrer"
	@echo "  make urls        - Voir les URLs"
	@echo ""

check-env: ## 🔍 Vérifier le fichier .env
	@if [ -f "$(PROJECT_DIR)/.env" ]; then \
		echo "$(GREEN)✅ Fichier .env trouvé$(NC)"; \
		echo "$(YELLOW)Contenu (sensible masqué):$(NC)"; \
		cat $(PROJECT_DIR)/.env | sed 's/=.*/=****/'; \
	else \
		echo "$(RED)❌ Fichier .env non trouvé$(NC)"; \
		echo "$(YELLOW)Exécutez: make setup$(NC)"; \
	fi

docs: ## 📚 Ouvrir la documentation
	@echo "$(GREEN)📚 Documentation disponible:$(NC)"
	@echo "  • QUICK-START.md    - Guide de démarrage"
	@echo "  • report.html       - Rapport de déploiement"
	@echo "  • test-report.html  - Rapport de tests"
	@if command -v xdg-open > /dev/null 2>&1; then \
		xdg-open QUICK-START.md 2>/dev/null || true; \
	elif command -v open > /dev/null 2>&1; then \
		open QUICK-START.md 2>/dev/null || true; \
	fi

# ============================================================================
# CONFIGURATION
# ============================================================================

init: ## 🎬 Initialiser le projet (première utilisation)
	@echo "$(BLUE)╔═══════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║     INITIALISATION DU PROJET                      ║$(NC)"
	@echo "$(BLUE)╚═══════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)1. Création des répertoires...$(NC)"
	@mkdir -p $(LOGS_DIR)
	@mkdir -p $(PROJECT_DIR)
	@echo "$(GREEN)✅ Répertoires créés$(NC)"
	@echo ""
	@echo "$(GREEN)2. Attribution des permissions...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/*.sh 2>/dev/null || true
	@echo "$(GREEN)✅ Permissions configurées$(NC)"
	@echo ""
	@echo "$(GREEN)3. Prêt!$(NC)"
	@echo ""
	@echo "$(YELLOW)🎯 Prochaine étape:$(NC) make all"
	@echo ""

permissions: ## 🔐 Corriger les permissions des scripts
	@echo "$(GREEN)🔐 Configuration des permissions...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/*.sh
	@echo "$(GREEN)✅ Permissions configurées$(NC)"

# ============================================================================
# AVANCÉ
# ============================================================================

update: ## 🔄 Mettre à jour le projet sur le VPS
	@echo "$(YELLOW)🔄 Mise à jour du projet...$(NC)"
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && git pull origin main'
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose up -d --build'
	@echo "$(GREEN)✅ Projet mis à jour$(NC)"

scale: ## 📈 Scaler un service (usage: make scale SERVICE=backend REPLICAS=3)
	@if [ -z "$(SERVICE)" ] || [ -z "$(REPLICAS)" ]; then \
		echo "$(RED)❌ Usage: make scale SERVICE=backend REPLICAS=3$(NC)"; \
		exit 1; \
	fi
	@ssh $(VPS_USER)@$(VPS_IP) 'cd /opt/veille-maroc && docker-compose up -d --scale $(SERVICE)=$(REPLICAS)'

stats: ## 📊 Statistiques Docker
	@echo "$(GREEN)📊 Statistiques des conteneurs...$(NC)"
	@ssh $(VPS_USER)@$(VPS_IP) 'docker stats --no-stream'

# ============================================================================
# VERSION
# ============================================================================

version: ## 📌 Afficher les versions
	@echo "$(BLUE)╔═══════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║              VERSIONS                              ║$(NC)"
	@echo "$(BLUE)╚═══════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Veille Stratégique Marocaine$(NC) v1.0.0"
	@echo ""
	@echo "$(YELLOW)Local:$(NC)"
	@docker --version
	@docker-compose --version
	@echo ""
	@echo "$(YELLOW)VPS (si accessible):$(NC)"
	@ssh $(VPS_USER)@$(VPS_IP) 'docker --version && docker-compose --version' 2>/dev/null || echo "VPS non accessible"

# ============================================================================
# DEFAULT
# ============================================================================

.DEFAULT_GOAL := help
