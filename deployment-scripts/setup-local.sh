#!/bin/bash

#################################################
# 🚀 SETUP LOCAL - Veille Stratégique Marocaine
# Prépare l'environnement local pour le déploiement
#################################################

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/deployment.log"
REPO_URL="https://github.com/salimxy/veille-maroc"
SOURCE_DIR="$HOME/Downloads/files"
PROJECT_DIR="./veille-maroc"

# Fichiers requis
REQUIRED_FILES=(
    "docker-compose.yml"
    "database-init.sql"
    "backend-server.js"
    "backend-package.json"
    "backend-Dockerfile"
    "frontend-package.json"
    "frontend-Dockerfile"
    "n8n-collecte.json"
    "n8n-analyse.json"
    "n8n-notification.json"
    "README.md"
    "ARCHITECTURE.md"
    "API.md"
    ".env.example"
    "nginx.conf"
    "sources-rss.json"
    "package.json"
)

#################################################
# Fonctions utilitaires
#################################################

log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} - ${message}" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"
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

progress_bar() {
    local duration=$1
    local steps=20
    local step_duration=$((duration / steps))

    echo -n "["
    for ((i=0; i<steps; i++)); do
        echo -n "="
        sleep $step_duration
    done
    echo "] Done!"
}

#################################################
# Vérifications préalables
#################################################

check_prerequisites() {
    print_header "Vérification des prérequis"

    # Vérifier Docker
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
        print_success "Docker installé (version $docker_version)"
    else
        print_error "Docker n'est pas installé"
        echo "Installation requise: https://docs.docker.com/get-docker/"
        exit 1
    fi

    # Vérifier Docker Compose
    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
        local compose_version=$(docker-compose --version 2>/dev/null || docker compose version 2>/dev/null | awk '{print $4}')
        print_success "Docker Compose installé (version $compose_version)"
    else
        print_error "Docker Compose n'est pas installé"
        exit 1
    fi

    # Vérifier Git
    if command -v git &> /dev/null; then
        print_success "Git installé"
    else
        print_error "Git n'est pas installé"
        exit 1
    fi

    # Vérifier SSH
    if command -v ssh &> /dev/null; then
        print_success "SSH disponible"
    else
        print_warning "SSH non disponible (nécessaire pour le déploiement VPS)"
    fi

    # Vérifier curl
    if command -v curl &> /dev/null; then
        print_success "curl disponible"
    else
        print_error "curl n'est pas installé"
        exit 1
    fi

    # Vérifier la connexion Docker
    if docker ps &> /dev/null; then
        print_success "Docker daemon est actif"
    else
        print_error "Docker daemon n'est pas actif"
        echo "Démarrez Docker et réessayez"
        exit 1
    fi
}

#################################################
# Création de la structure
#################################################

create_directory_structure() {
    print_header "Création de la structure des répertoires"

    mkdir -p "$LOG_DIR"
    mkdir -p "$PROJECT_DIR"/{backend,frontend,n8n,database,nginx}
    mkdir -p "$PROJECT_DIR"/docs
    mkdir -p "$PROJECT_DIR"/data/{postgres,n8n}

    print_success "Structure des répertoires créée"

    # Afficher l'arborescence
    print_info "Structure créée:"
    tree -L 2 "$PROJECT_DIR" 2>/dev/null || find "$PROJECT_DIR" -maxdepth 2 -type d | sed 's|[^/]*/| |g'
}

#################################################
# Clone ou copie des fichiers
#################################################

setup_repository() {
    print_header "Configuration du repository"

    if [ -d "$PROJECT_DIR/.git" ]; then
        print_info "Repository déjà cloné, mise à jour..."
        cd "$PROJECT_DIR"
        git pull origin main 2>&1 | tee -a "$LOG_FILE" || print_warning "Impossible de mettre à jour le repository"
        cd ..
    else
        print_info "Tentative de clone du repository..."
        if git clone "$REPO_URL" "$PROJECT_DIR" 2>&1 | tee -a "$LOG_FILE"; then
            print_success "Repository cloné avec succès"
        else
            print_warning "Impossible de cloner le repository (peut ne pas exister encore)"
            print_info "Continuons avec la configuration locale..."
        fi
    fi

    # Copier les fichiers depuis Downloads si disponibles
    if [ -d "$SOURCE_DIR" ]; then
        print_info "Copie des fichiers depuis $SOURCE_DIR"
        cp -r "$SOURCE_DIR"/* "$PROJECT_DIR"/ 2>&1 | tee -a "$LOG_FILE" || print_warning "Certains fichiers n'ont pas pu être copiés"
        print_success "Fichiers copiés"
    else
        print_warning "Répertoire source $SOURCE_DIR non trouvé"
        print_info "Assurez-vous que les fichiers sont dans le bon répertoire"
    fi
}

#################################################
# Validation des fichiers
#################################################

validate_files() {
    print_header "Validation des fichiers requis"

    local missing_files=()
    local found_count=0

    cd "$PROJECT_DIR"

    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$file" ] || find . -name "$file" -type f | grep -q .; then
            print_success "Trouvé: $file"
            ((found_count++))
        else
            print_error "Manquant: $file"
            missing_files+=("$file")
        fi
    done

    cd ..

    echo ""
    print_info "Fichiers trouvés: $found_count/${#REQUIRED_FILES[@]}"

    if [ ${#missing_files[@]} -gt 0 ]; then
        print_warning "Fichiers manquants: ${missing_files[*]}"
        print_info "Vous devrez créer ces fichiers avant le déploiement"
    else
        print_success "Tous les fichiers requis sont présents!"
    fi
}

#################################################
# Configuration .env
#################################################

create_env_file() {
    print_header "Configuration du fichier .env"

    local env_file="$PROJECT_DIR/.env"
    local env_example="$PROJECT_DIR/.env.example"

    if [ -f "$env_file" ]; then
        print_warning "Le fichier .env existe déjà"
        read -p "Voulez-vous le recréer? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Conservation du fichier .env existant"
            return
        fi
    fi

    # Demander les informations
    echo ""
    print_info "Configuration des variables d'environnement"
    echo ""

    read -p "🌍 Adresse IP du VPS: " vps_ip
    read -sp "🔐 Mot de passe PostgreSQL: " postgres_password
    echo
    read -sp "🔑 Clé API OpenRouter: " openrouter_key
    echo
    read -p "📧 Email administrateur: " admin_email
    read -sp "📬 Mot de passe Gmail (app password): " gmail_password
    echo

    # Créer le fichier .env
    cat > "$env_file" << EOF
# Configuration générée le $(date)

# VPS Configuration
VPS_IP=$vps_ip
VPS_USER=root

# Database Configuration
POSTGRES_USER=veille_user
POSTGRES_PASSWORD=$postgres_password
POSTGRES_DB=veille_maroc
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# N8N Configuration
N8N_HOST=n8n.veille-maroc.local
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=changeme123

# API Configuration
API_HOST=backend
API_PORT=3001
NODE_ENV=production

# OpenRouter Configuration
OPENROUTER_API_KEY=$openrouter_key
OPENROUTER_MODEL=openai/gpt-3.5-turbo

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=$admin_email
SMTP_PASSWORD=$gmail_password
ADMIN_EMAIL=$admin_email

# Frontend Configuration
FRONTEND_PORT=3000
API_URL=http://localhost:3001

# Security
JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || echo "change-this-secret-key")
SESSION_SECRET=$(openssl rand -base64 32 2>/dev/null || echo "change-this-session-secret")

# Timezone
TZ=Africa/Casablanca
EOF

    chmod 600 "$env_file"
    print_success "Fichier .env créé avec succès"
    print_warning "IMPORTANT: Ne partagez jamais ce fichier!"
}

#################################################
# Récapitulatif
#################################################

print_summary() {
    print_header "Récapitulatif de l'installation"

    echo -e "${GREEN}✅ Environnement local configuré${NC}"
    echo ""
    echo "📁 Répertoire du projet: $PROJECT_DIR"
    echo "📝 Fichier de logs: $LOG_FILE"
    echo "🔧 Fichier de configuration: $PROJECT_DIR/.env"
    echo ""
    echo -e "${BLUE}Prochaines étapes:${NC}"
    echo "  1️⃣  ./validate.sh          - Valider les fichiers"
    echo "  2️⃣  ./deploy-vps.sh        - Déployer sur le VPS"
    echo "  3️⃣  ./test-services.sh     - Tester les services"
    echo "  4️⃣  ./setup-n8n.sh         - Configurer N8N"
    echo ""
    print_success "Setup terminé avec succès! 🎉"
}

#################################################
# Main
#################################################

main() {
    clear
    print_header "🚀 SETUP LOCAL - Veille Stratégique Marocaine"

    log "=== Démarrage du setup local ==="

    check_prerequisites
    create_directory_structure
    setup_repository
    validate_files
    create_env_file
    print_summary

    log "=== Setup local terminé avec succès ==="
}

# Exécution
main "$@"
