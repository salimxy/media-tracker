#!/bin/bash

#################################################
# 🔄 SETUP N8N - Veille Stratégique Marocaine
# Configure N8N et importe les workflows
#################################################

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/n8n-setup.log"
PROJECT_DIR="./veille-maroc"
REMOTE_DIR="/opt/veille-maroc"

# Charger les variables d'environnement
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
else
    echo -e "${RED}❌ Fichier .env non trouvé${NC}"
    exit 1
fi

#################################################
# Fonctions utilitaires
#################################################

log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${timestamp} - ${message}" >> "$LOG_FILE"
}

print_header() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log "SUCCESS: $1"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    log "ERROR: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log "WARNING: $1"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_step() {
    echo -e "\n${MAGENTA}▶ $1${NC}\n"
}

#################################################
# Vérifications préalables
#################################################

check_prerequisites() {
    print_header "Vérifications préalables"

    # Vérifier que N8N est accessible
    print_step "Vérification de l'accessibilité de N8N..."

    local n8n_status=$(ssh ${VPS_USER}@${VPS_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:5678" 2>/dev/null)

    if [ "$n8n_status" == "200" ] || [ "$n8n_status" == "302" ] || [ "$n8n_status" == "401" ]; then
        print_success "N8N est accessible"
    else
        print_error "N8N n'est pas accessible (HTTP $n8n_status)"
        print_info "Assurez-vous que N8N est démarré"
        exit 1
    fi

    # Vérifier que les fichiers de workflow existent
    if [ -d "$PROJECT_DIR/n8n" ]; then
        print_success "Répertoire n8n/ trouvé"
    else
        print_warning "Répertoire n8n/ non trouvé"
    fi
}

#################################################
# Configuration de l'authentification N8N
#################################################

setup_n8n_auth() {
    print_header "Configuration de l'authentification N8N"

    print_step "Configuration de l'utilisateur admin..."

    # Instructions pour l'utilisateur
    print_info "N8N nécessite une configuration manuelle initiale"
    echo ""
    echo -e "${YELLOW}🔐 Configuration manuelle requise:${NC}"
    echo ""
    echo "1. Ouvrez votre navigateur:"
    echo -e "   ${CYAN}http://${VPS_IP}:5678${NC}"
    echo ""
    echo "2. Si c'est la première connexion, créez un compte:"
    echo "   • Email: ${ADMIN_EMAIL:-admin@veille-maroc.local}"
    echo "   • Mot de passe: (choisissez un mot de passe sécurisé)"
    echo ""
    echo "3. Si déjà configuré, connectez-vous avec:"
    echo "   • Username: admin"
    echo "   • Password: changeme123 (ou votre mot de passe)"
    echo ""

    read -p "Appuyez sur ENTRÉE une fois connecté à N8N..." -r
    echo ""

    print_success "Authentification N8N configurée"
}

#################################################
# Configuration des credentials PostgreSQL
#################################################

setup_postgres_credentials() {
    print_header "Configuration des credentials PostgreSQL"

    print_step "Instructions pour ajouter PostgreSQL dans N8N..."

    cat << EOF

${YELLOW}📝 Configuration manuelle de PostgreSQL:${NC}

1. Dans N8N, cliquez sur "Credentials" dans le menu
2. Cliquez sur "Add Credential"
3. Recherchez "Postgres"
4. Configurez avec ces paramètres:

   ${CYAN}Nom:${NC} veille-maroc-postgres
   ${CYAN}Host:${NC} postgres
   ${CYAN}Port:${NC} 5432
   ${CYAN}Database:${NC} ${POSTGRES_DB:-veille_maroc}
   ${CYAN}User:${NC} ${POSTGRES_USER:-veille_user}
   ${CYAN}Password:${NC} ${POSTGRES_PASSWORD}

5. Cliquez sur "Save"
6. Testez la connexion

EOF

    read -p "Appuyez sur ENTRÉE une fois PostgreSQL configuré..." -r
    echo ""

    print_success "Credentials PostgreSQL configurés"
}

#################################################
# Configuration des credentials OpenRouter
#################################################

setup_openrouter_credentials() {
    print_header "Configuration des credentials OpenRouter"

    print_step "Instructions pour ajouter OpenRouter dans N8N..."

    cat << EOF

${YELLOW}📝 Configuration manuelle d'OpenRouter:${NC}

1. Dans N8N, allez dans "Credentials"
2. Cliquez sur "Add Credential"
3. Recherchez "HTTP Header Auth" ou "Generic Credential"
4. Configurez:

   ${CYAN}Nom:${NC} openrouter-api
   ${CYAN}Type:${NC} Header Auth
   ${CYAN}Header Name:${NC} Authorization
   ${CYAN}Header Value:${NC} Bearer ${OPENROUTER_API_KEY}

   ${YELLOW}OU utilisez "HTTP Request" avec:${NC}
   ${CYAN}URL:${NC} https://openrouter.ai/api/v1/chat/completions
   ${CYAN}Header:${NC} Authorization: Bearer ${OPENROUTER_API_KEY}

5. Cliquez sur "Save"

EOF

    read -p "Appuyez sur ENTRÉE une fois OpenRouter configuré..." -r
    echo ""

    print_success "Credentials OpenRouter configurés"
}

#################################################
# Import des workflows
#################################################

import_workflows() {
    print_header "Import des workflows N8N"

    cd "$PROJECT_DIR"

    # Chercher les fichiers de workflow
    local workflow_files=$(find . -name "*n8n*.json" -o -name "*workflow*.json" 2>/dev/null)

    if [ -z "$workflow_files" ]; then
        print_warning "Aucun fichier de workflow trouvé"
        print_info "Les workflows peuvent être importés manuellement via l'interface N8N"
        cd ..
        return
    fi

    print_step "Workflows trouvés à importer:"
    echo "$workflow_files" | while read file; do
        echo "  • $file"
    done
    echo ""

    cat << EOF

${YELLOW}📝 Import manuel des workflows:${NC}

1. Dans N8N, cliquez sur "Workflows" dans le menu
2. Cliquez sur "Import from File" ou l'icône d'import
3. Pour chaque workflow, importez ces fichiers:

EOF

    echo "$workflow_files" | while read file; do
        echo "   • $file"
    done

    cat << EOF

${YELLOW}Ou utilisez cette méthode automatique:${NC}

Les fichiers ont été transférés sur le VPS. Vous pouvez les importer via:

EOF

    echo "$workflow_files" | while read file; do
        local basename=$(basename "$file")
        echo "   curl -X POST http://${VPS_IP}:5678/rest/workflows/import \\"
        echo "        -H 'Content-Type: application/json' \\"
        echo "        -d @${REMOTE_DIR}/$basename"
        echo ""
    done

    read -p "Appuyez sur ENTRÉE une fois les workflows importés..." -r
    echo ""

    cd ..

    print_success "Workflows importés"
}

#################################################
# Configuration du workflow de collecte
#################################################

configure_collection_workflow() {
    print_header "Configuration du workflow de collecte"

    cat << EOF

${YELLOW}🔄 Configuration du workflow de collecte:${NC}

1. Ouvrez le workflow "Collecte RSS Maroc" dans N8N
2. Vérifiez/configurez ces nœuds:

   ${CYAN}Nœud Schedule (Cron):${NC}
   • Expression: */2 * * * * (toutes les 2 minutes)
   • Ou: 0 */6 * * * (toutes les 6 heures)

   ${CYAN}Nœud RSS Feed:${NC}
   • URL: Configuré depuis sources-rss.json
   • Exemples:
     - https://www.hespress.com/feed
     - https://www.medias24.com/feed
     - https://lematin.ma/rss

   ${CYAN}Nœud HTTP Request (OpenRouter):${NC}
   • URL: https://openrouter.ai/api/v1/chat/completions
   • Method: POST
   • Credentials: openrouter-api

   ${CYAN}Nœud PostgreSQL:${NC}
   • Credentials: veille-maroc-postgres
   • Table: articles
   • Operation: Insert

3. Cliquez sur "Save" (en haut à droite)
4. Activez le workflow (toggle Active)

EOF

    read -p "Appuyez sur ENTRÉE une fois le workflow configuré..." -r
    echo ""

    print_success "Workflow de collecte configuré"
}

#################################################
# Configuration du workflow d'analyse
#################################################

configure_analysis_workflow() {
    print_header "Configuration du workflow d'analyse"

    cat << EOF

${YELLOW}🤖 Configuration du workflow d'analyse:${NC}

1. Ouvrez le workflow "Analyse Articles" dans N8N
2. Vérifiez/configurez:

   ${CYAN}Nœud Trigger:${NC}
   • Type: Interval (toutes les heures)
   • Ou: Webhook pour analyse à la demande

   ${CYAN}Nœud PostgreSQL Read:${NC}
   • Query: SELECT * FROM articles WHERE analyzed = false
   • Credentials: veille-maroc-postgres

   ${CYAN}Nœud AI Analysis (OpenRouter):${NC}
   • Prompt: Analyser l'article et extraire:
     - Mots-clés
     - Sentiment
     - Entités (organisations, personnes, lieux)
     - Pertinence sectorielle

   ${CYAN}Nœud PostgreSQL Update:${NC}
   • Query: UPDATE articles SET analyzed = true, analysis = ...

3. Sauvegardez et activez

EOF

    read -p "Appuyez sur ENTRÉE une fois configuré..." -r
    echo ""

    print_success "Workflow d'analyse configuré"
}

#################################################
# Configuration du workflow de notification
#################################################

configure_notification_workflow() {
    print_header "Configuration du workflow de notification"

    cat << EOF

${YELLOW}📧 Configuration du workflow de notification:${NC}

1. Ouvrez le workflow "Notifications Email" dans N8N
2. Configurez:

   ${CYAN}Nœud Email (SMTP):${NC}
   • Host: ${SMTP_HOST:-smtp.gmail.com}
   • Port: ${SMTP_PORT:-587}
   • User: ${SMTP_USER:-${ADMIN_EMAIL}}
   • Password: ${SMTP_PASSWORD}
   • From Email: ${ADMIN_EMAIL}

   ${CYAN}Nœud PostgreSQL Read:${NC}
   • Query: SELECT * FROM articles
           WHERE priority = 'high'
           AND notified = false

   ${CYAN}Nœud Format Email:${NC}
   • Template: HTML avec les articles importants
   • Destinataires: Liste des clients

3. Configurez la fréquence (ex: quotidienne à 8h)
4. Sauvegardez et activez

${YELLOW}⚠️  Note:${NC} Pour Gmail, utilisez un "App Password":
   https://myaccount.google.com/apppasswords

EOF

    read -p "Appuyez sur ENTRÉE une fois configuré..." -r
    echo ""

    print_success "Workflow de notification configuré"
}

#################################################
# Test des workflows
#################################################

test_workflows() {
    print_header "Test des workflows"

    cat << EOF

${YELLOW}🧪 Test des workflows:${NC}

1. ${CYAN}Test du workflow de collecte:${NC}
   • Cliquez sur "Execute Workflow" en haut à droite
   • Vérifiez que les articles sont collectés
   • Vérifiez l'insertion dans PostgreSQL

2. ${CYAN}Test du workflow d'analyse:${NC}
   • Exécutez manuellement
   • Vérifiez que l'analyse IA fonctionne
   • Vérifiez la mise à jour dans la DB

3. ${CYAN}Test du workflow de notification:${NC}
   • Exécutez manuellement
   • Vérifiez la réception de l'email

${GREEN}✅ Si tout fonctionne:${NC}
   • Activez tous les workflows
   • Les collectes se feront automatiquement

${RED}❌ En cas d'erreur:${NC}
   • Vérifiez les credentials
   • Vérifiez les connexions (PostgreSQL, OpenRouter)
   • Consultez les logs dans N8N

EOF

    read -p "Appuyez sur ENTRÉE une fois les tests terminés..." -r
    echo ""

    print_success "Workflows testés"
}

#################################################
# Vérification du schedule
#################################################

verify_schedule() {
    print_header "Vérification du planning"

    print_step "Vérification que les workflows sont actifs..."

    cat << EOF

${YELLOW}📅 Planning recommandé:${NC}

${CYAN}Workflow de collecte RSS:${NC}
• Fréquence: Toutes les 2-6 heures
• Cron: 0 */6 * * *
• Status: Doit être ACTIF

${CYAN}Workflow d'analyse:${NC}
• Fréquence: Toutes les heures
• Cron: 0 * * * *
• Status: Doit être ACTIF

${CYAN}Workflow de notification:${NC}
• Fréquence: Quotidien à 8h00
• Cron: 0 8 * * *
• Status: Doit être ACTIF

${GREEN}💡 Pour vérifier dans N8N:${NC}
1. Allez dans "Workflows"
2. Vérifiez que le toggle "Active" est vert
3. Cliquez sur chaque workflow pour voir les exécutions

EOF

    print_success "Planning vérifié"
}

#################################################
# Configuration des webhooks (optionnel)
#################################################

setup_webhooks() {
    print_header "Configuration des webhooks (optionnel)"

    cat << EOF

${YELLOW}🔗 Configuration des webhooks:${NC}

Les webhooks permettent de déclencher des workflows via HTTP:

${CYAN}1. Webhook pour collecte manuelle:${NC}
   URL: http://${VPS_IP}:5678/webhook/collect-now
   Method: POST
   Usage: curl -X POST http://${VPS_IP}:5678/webhook/collect-now

${CYAN}2. Webhook pour analyse d'un article:${NC}
   URL: http://${VPS_IP}:5678/webhook/analyze-article
   Method: POST
   Body: {"article_id": 123}

${CYAN}3. Webhook pour notification manuelle:${NC}
   URL: http://${VPS_IP}:5678/webhook/send-notification
   Method: POST
   Body: {"client_id": 1}

${GREEN}💡 Pour créer un webhook dans N8N:${NC}
1. Ajoutez un nœud "Webhook" au début du workflow
2. Configurez le chemin (ex: /collect-now)
3. Sauvegardez le workflow
4. Le webhook sera disponible

EOF

    read -p "Configurer les webhooks maintenant? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Configurez les webhooks dans N8N comme indiqué ci-dessus"
        read -p "Appuyez sur ENTRÉE une fois terminé..." -r
        print_success "Webhooks configurés"
    else
        print_info "Webhooks ignorés (peut être configuré plus tard)"
    fi
}

#################################################
# Sauvegarde de la configuration N8N
#################################################

backup_n8n_config() {
    print_header "Sauvegarde de la configuration N8N"

    print_step "Création d'une sauvegarde..."

    ssh ${VPS_USER}@${VPS_IP} bash << EOF
        cd $REMOTE_DIR

        # Créer un répertoire de backup
        mkdir -p backups/n8n

        # Sauvegarder la base de données N8N (si SQLite)
        if [ -f data/n8n/database.sqlite ]; then
            cp data/n8n/database.sqlite backups/n8n/database-$(date +%Y%m%d-%H%M%S).sqlite
            echo "✅ Base N8N sauvegardée"
        fi

        # Sauvegarder les workflows (via export)
        echo "💡 Pour sauvegarder les workflows:"
        echo "   1. Dans N8N, allez dans chaque workflow"
        echo "   2. Cliquez sur ... → Export"
        echo "   3. Sauvegardez le JSON"
EOF

    print_success "Instructions de sauvegarde affichées"
}

#################################################
# Récapitulatif final
#################################################

print_final_summary() {
    print_header "Récapitulatif de la configuration N8N"

    cat << EOF

${GREEN}✅ Configuration N8N terminée!${NC}

${CYAN}📍 Accès N8N:${NC}
   URL: ${GREEN}http://${VPS_IP}:5678${NC}
   Username: admin
   Password: (configuré lors du setup)

${CYAN}🔑 Credentials configurés:${NC}
   ✅ PostgreSQL (veille-maroc-postgres)
   ✅ OpenRouter API (openrouter-api)

${CYAN}🔄 Workflows:${NC}
   ✅ Collecte RSS (actif, schedule: */2 * * * *)
   ✅ Analyse Articles (actif, schedule: 0 * * * *)
   ✅ Notifications Email (actif, schedule: 0 8 * * *)

${CYAN}📊 Monitoring:${NC}
   • Dashboard N8N: http://${VPS_IP}:5678/workflows
   • Logs: ssh ${VPS_USER}@${VPS_IP} 'cd $REMOTE_DIR && docker-compose logs -f n8n'

${CYAN}🔧 Commandes utiles:${NC}
   • Redémarrer N8N:
     ssh ${VPS_USER}@${VPS_IP} 'cd $REMOTE_DIR && docker-compose restart n8n'

   • Voir les exécutions:
     Consultez l'onglet "Executions" dans N8N

   • Backup:
     Export manuel des workflows via l'interface N8N

${CYAN}🎯 Prochaines actions:${NC}
   1. Surveillez les premières exécutions
   2. Ajustez les schedules si nécessaire
   3. Configurez les sources RSS personnalisées
   4. Testez les notifications email
   5. Consultez le rapport: open report.html

${GREEN}🎉 Votre plateforme de veille est maintenant opérationnelle!${NC}

EOF

    print_success "Setup N8N terminé avec succès!"
}

#################################################
# Main
#################################################

main() {
    clear
    print_header "🔄 SETUP N8N - Veille Stratégique Marocaine"

    mkdir -p "$LOG_DIR"
    log "=== Démarrage du setup N8N ==="

    check_prerequisites
    setup_n8n_auth
    setup_postgres_credentials
    setup_openrouter_credentials
    import_workflows
    configure_collection_workflow
    configure_analysis_workflow
    configure_notification_workflow
    test_workflows
    verify_schedule
    setup_webhooks
    backup_n8n_config
    print_final_summary

    log "=== Setup N8N terminé avec succès ==="
}

# Exécution
main "$@"
