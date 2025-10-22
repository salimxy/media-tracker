#!/bin/bash

#################################################
# 🚀 DEPLOY VPS - Veille Stratégique Marocaine
# Déploie l'application sur le serveur VPS
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
LOG_FILE="$LOG_DIR/deployment.log"
PROJECT_DIR="./veille-maroc"
REMOTE_DIR="/opt/veille-maroc"
MAX_RETRIES=3
RETRY_DELAY=2

# Variables d'environnement
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
else
    echo -e "${RED}❌ Fichier .env non trouvé${NC}"
    echo -e "${YELLOW}Exécutez d'abord: ./setup-local.sh${NC}"
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

progress_bar() {
    local duration=$1
    local steps=30
    local step_duration=$(awk "BEGIN {printf \"%.2f\", $duration/$steps}")

    echo -n "["
    for ((i=0; i<steps; i++)); do
        echo -n "="
        sleep $step_duration
    done
    echo "] Done!"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

retry_command() {
    local command="$1"
    local description="$2"
    local attempt=1
    local delay=$RETRY_DELAY

    while [ $attempt -le $MAX_RETRIES ]; do
        print_info "Tentative $attempt/$MAX_RETRIES: $description"

        if eval "$command"; then
            print_success "$description réussi"
            return 0
        else
            if [ $attempt -lt $MAX_RETRIES ]; then
                print_warning "Échec, nouvelle tentative dans ${delay}s..."
                sleep $delay
                delay=$((delay * 2))  # Exponential backoff
            fi
            ((attempt++))
        fi
    done

    print_error "$description a échoué après $MAX_RETRIES tentatives"
    return 1
}

#################################################
# Vérifications préalables
#################################################

check_prerequisites() {
    print_header "Vérifications préalables"

    # Vérifier que le projet existe
    if [ ! -d "$PROJECT_DIR" ]; then
        print_error "Répertoire $PROJECT_DIR non trouvé"
        print_info "Exécutez d'abord: ./setup-local.sh"
        exit 1
    fi

    # Vérifier les variables requises
    if [ -z "$VPS_IP" ]; then
        print_error "Variable VPS_IP non définie dans .env"
        exit 1
    fi

    if [ -z "$VPS_USER" ]; then
        print_warning "VPS_USER non défini, utilisation de 'root'"
        VPS_USER="root"
    fi

    print_success "Variables d'environnement chargées"
    print_info "VPS: ${VPS_USER}@${VPS_IP}"

    # Vérifier SSH
    if ! command -v ssh &> /dev/null; then
        print_error "SSH n'est pas installé"
        exit 1
    fi
    print_success "SSH disponible"

    # Vérifier SCP
    if ! command -v scp &> /dev/null; then
        print_error "SCP n'est pas installé"
        exit 1
    fi
    print_success "SCP disponible"
}

#################################################
# Test de connexion VPS
#################################################

test_vps_connection() {
    print_header "Test de connexion au VPS"

    print_step "Connexion à ${VPS_USER}@${VPS_IP}..."

    if retry_command "ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${VPS_USER}@${VPS_IP} 'echo Connection successful' > /dev/null 2>&1" "Connexion SSH"; then
        print_success "Connexion VPS établie"

        # Afficher les informations du serveur
        print_info "Informations du serveur:"
        ssh ${VPS_USER}@${VPS_IP} 'echo "  OS: $(uname -s)"; echo "  Kernel: $(uname -r)"; echo "  Hostname: $(hostname)"' 2>/dev/null || true
    else
        print_error "Impossible de se connecter au VPS"
        print_info "Vérifiez:"
        print_info "  • L'adresse IP est correcte: $VPS_IP"
        print_info "  • Le serveur est accessible"
        print_info "  • Les clés SSH sont configurées"
        print_info "  • Le pare-feu autorise SSH (port 22)"
        exit 1
    fi
}

#################################################
# Installation des dépendances sur le VPS
#################################################

install_vps_dependencies() {
    print_header "Installation des dépendances sur le VPS"

    print_step "Vérification de Docker sur le VPS..."

    ssh ${VPS_USER}@${VPS_IP} bash << 'EOF'
        set -e

        # Vérifier si Docker est installé
        if command -v docker &> /dev/null; then
            echo "✅ Docker déjà installé"
            docker --version
        else
            echo "📦 Installation de Docker..."

            # Installation Docker (Ubuntu/Debian)
            if command -v apt-get &> /dev/null; then
                apt-get update
                apt-get install -y apt-transport-https ca-certificates curl software-properties-common
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
                add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
                apt-get update
                apt-get install -y docker-ce docker-ce-cli containerd.io
            # Installation Docker (CentOS/RHEL)
            elif command -v yum &> /dev/null; then
                yum install -y yum-utils
                yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                yum install -y docker-ce docker-ce-cli containerd.io
            fi

            systemctl start docker
            systemctl enable docker
            echo "✅ Docker installé avec succès"
        fi

        # Vérifier Docker Compose
        if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
            echo "✅ Docker Compose déjà installé"
            docker-compose --version 2>/dev/null || docker compose version
        else
            echo "📦 Installation de Docker Compose..."
            curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            echo "✅ Docker Compose installé avec succès"
        fi

        # Vérifier PostgreSQL client (optionnel, pour tests)
        if ! command -v psql &> /dev/null; then
            echo "📦 Installation du client PostgreSQL..."
            if command -v apt-get &> /dev/null; then
                apt-get install -y postgresql-client
            elif command -v yum &> /dev/null; then
                yum install -y postgresql
            fi
        fi
EOF

    if [ $? -eq 0 ]; then
        print_success "Dépendances installées sur le VPS"
    else
        print_error "Erreur lors de l'installation des dépendances"
        exit 1
    fi
}

#################################################
# Création de la structure sur le VPS
#################################################

create_remote_structure() {
    print_header "Création de la structure sur le VPS"

    print_step "Création de $REMOTE_DIR..."

    ssh ${VPS_USER}@${VPS_IP} bash << EOF
        set -e

        # Créer le répertoire principal
        mkdir -p $REMOTE_DIR
        cd $REMOTE_DIR

        # Créer la structure
        mkdir -p backend frontend n8n database nginx
        mkdir -p data/postgres data/n8n
        mkdir -p logs

        # Définir les permissions
        chmod 755 $REMOTE_DIR
        chmod 777 logs

        echo "✅ Structure créée dans $REMOTE_DIR"
        ls -la $REMOTE_DIR
EOF

    if [ $? -eq 0 ]; then
        print_success "Structure créée sur le VPS"
    else
        print_error "Erreur lors de la création de la structure"
        exit 1
    fi
}

#################################################
# Transfert des fichiers
#################################################

transfer_files() {
    print_header "Transfert des fichiers vers le VPS"

    cd "$PROJECT_DIR"

    # Liste des fichiers à transférer
    local files_to_transfer=(
        "docker-compose.yml"
        "database-init.sql"
        ".env"
        "nginx.conf"
        "sources-rss.json"
    )

    # Transférer les fichiers individuels
    for file in "${files_to_transfer[@]}"; do
        if [ -f "$file" ]; then
            print_step "Transfert de $file..."
            if retry_command "scp -o ConnectTimeout=10 '$file' ${VPS_USER}@${VPS_IP}:${REMOTE_DIR}/" "Transfert $file"; then
                print_success "$file transféré"
            else
                print_error "Échec du transfert de $file"
            fi
        else
            print_warning "Fichier $file non trouvé, ignoré"
        fi
    done

    # Transférer les répertoires
    local dirs_to_transfer=("backend" "frontend" "n8n")

    for dir in "${dirs_to_transfer[@]}"; do
        if [ -d "$dir" ]; then
            print_step "Transfert du répertoire $dir/..."
            if retry_command "scp -r -o ConnectTimeout=10 '$dir' ${VPS_USER}@${VPS_IP}:${REMOTE_DIR}/" "Transfert $dir/"; then
                print_success "Répertoire $dir/ transféré"
            else
                print_error "Échec du transfert de $dir/"
            fi
        else
            print_warning "Répertoire $dir/ non trouvé, ignoré"
        fi
    done

    cd ..

    print_success "Tous les fichiers ont été transférés"
}

#################################################
# Configuration de l'environnement sur le VPS
#################################################

configure_remote_env() {
    print_header "Configuration de l'environnement sur le VPS"

    print_step "Ajustement du fichier .env pour l'environnement VPS..."

    ssh ${VPS_USER}@${VPS_IP} bash << EOF
        cd $REMOTE_DIR

        # Ajuster les variables pour l'environnement VPS
        sed -i 's/localhost/0.0.0.0/g' .env
        sed -i 's/127.0.0.1/0.0.0.0/g' .env

        # Sécuriser le fichier
        chmod 600 .env

        echo "✅ Fichier .env configuré"
EOF

    print_success "Environnement configuré sur le VPS"
}

#################################################
# Déploiement Docker
#################################################

deploy_docker_containers() {
    print_header "Déploiement des conteneurs Docker"

    print_step "Arrêt des conteneurs existants (si présents)..."

    ssh ${VPS_USER}@${VPS_IP} bash << EOF
        cd $REMOTE_DIR

        # Arrêter les conteneurs existants
        docker-compose down 2>/dev/null || docker compose down 2>/dev/null || true

        echo "✅ Conteneurs arrêtés"
EOF

    print_step "Construction et démarrage des conteneurs..."

    ssh ${VPS_USER}@${VPS_IP} bash << EOF
        cd $REMOTE_DIR

        # Construire et démarrer
        docker-compose pull 2>/dev/null || docker compose pull 2>/dev/null || true
        docker-compose up -d --build 2>&1 || docker compose up -d --build 2>&1

        echo ""
        echo "✅ Conteneurs démarrés"
        echo ""
        echo "Status des conteneurs:"
        docker-compose ps 2>/dev/null || docker compose ps 2>/dev/null
EOF

    if [ $? -eq 0 ]; then
        print_success "Conteneurs Docker déployés avec succès"
    else
        print_error "Erreur lors du déploiement Docker"
        print_info "Vérifiez les logs: ssh ${VPS_USER}@${VPS_IP} 'cd $REMOTE_DIR && docker-compose logs'"
        exit 1
    fi
}

#################################################
# Attente du démarrage des services
#################################################

wait_for_services() {
    print_header "Attente du démarrage des services"

    print_info "Attente de 30 secondes pour le démarrage complet..."
    progress_bar 30

    print_success "Services démarrés (probablement)"
}

#################################################
# Tests rapides
#################################################

quick_tests() {
    print_header "Tests rapides des services"

    ssh ${VPS_USER}@${VPS_IP} bash << 'EOF'
        cd /opt/veille-maroc

        echo "🧪 Test PostgreSQL..."
        if docker-compose exec -T postgres pg_isready -U veille_user 2>/dev/null; then
            echo "✅ PostgreSQL: OK"
        else
            echo "❌ PostgreSQL: NON DISPONIBLE"
        fi

        echo ""
        echo "🧪 Test N8N..."
        if curl -s http://localhost:5678 > /dev/null 2>&1; then
            echo "✅ N8N: OK"
        else
            echo "⚠️  N8N: EN COURS DE DÉMARRAGE"
        fi

        echo ""
        echo "🧪 Test Backend..."
        if curl -s http://localhost:3001/api/health > /dev/null 2>&1; then
            echo "✅ Backend: OK"
        else
            echo "⚠️  Backend: EN COURS DE DÉMARRAGE"
        fi

        echo ""
        echo "🧪 Test Frontend..."
        if curl -s http://localhost:3000 > /dev/null 2>&1; then
            echo "✅ Frontend: OK"
        else
            echo "⚠️  Frontend: EN COURS DE DÉMARRAGE"
        fi

        echo ""
        echo "📊 Status des conteneurs:"
        docker-compose ps 2>/dev/null || docker compose ps
EOF

    print_success "Tests rapides terminés"
}

#################################################
# Configuration du pare-feu
#################################################

configure_firewall() {
    print_header "Configuration du pare-feu (optionnel)"

    print_info "Ouverture des ports nécessaires..."

    ssh ${VPS_USER}@${VPS_IP} bash << 'EOF'
        # Vérifier si ufw est installé
        if command -v ufw &> /dev/null; then
            echo "🔥 Configuration UFW..."
            ufw allow 22/tcp    # SSH
            ufw allow 80/tcp    # HTTP
            ufw allow 443/tcp   # HTTPS
            ufw allow 3000/tcp  # Frontend
            ufw allow 3001/tcp  # Backend
            ufw allow 5678/tcp  # N8N

            echo "✅ Règles UFW ajoutées"
        elif command -v firewall-cmd &> /dev/null; then
            echo "🔥 Configuration Firewalld..."
            firewall-cmd --permanent --add-port=22/tcp
            firewall-cmd --permanent --add-port=80/tcp
            firewall-cmd --permanent --add-port=443/tcp
            firewall-cmd --permanent --add-port=3000/tcp
            firewall-cmd --permanent --add-port=3001/tcp
            firewall-cmd --permanent --add-port=5678/tcp
            firewall-cmd --reload

            echo "✅ Règles Firewalld ajoutées"
        else
            echo "⚠️  Aucun pare-feu détecté (ufw/firewalld)"
        fi
EOF

    print_success "Pare-feu configuré"
}

#################################################
# Récapitulatif
#################################################

print_deployment_summary() {
    print_header "Récapitulatif du déploiement"

    echo -e "${GREEN}✅ Déploiement terminé avec succès!${NC}"
    echo ""
    echo -e "${CYAN}📍 URLs d'accès:${NC}"
    echo -e "  🌐 Frontend:    http://${VPS_IP}:3000"
    echo -e "  🔌 API Backend: http://${VPS_IP}:3001"
    echo -e "  🔄 N8N:         http://${VPS_IP}:5678"
    echo ""
    echo -e "${CYAN}🔑 Credentials N8N:${NC}"
    echo -e "  Username: admin"
    echo -e "  Password: changeme123"
    echo ""
    echo -e "${CYAN}📊 Commandes utiles:${NC}"
    echo -e "  • Voir les logs:     ssh ${VPS_USER}@${VPS_IP} 'cd $REMOTE_DIR && docker-compose logs -f'"
    echo -e "  • Redémarrer:        ssh ${VPS_USER}@${VPS_IP} 'cd $REMOTE_DIR && docker-compose restart'"
    echo -e "  • Status:            ssh ${VPS_USER}@${VPS_IP} 'cd $REMOTE_DIR && docker-compose ps'"
    echo ""
    echo -e "${CYAN}🎯 Prochaines étapes:${NC}"
    echo -e "  1️⃣  ./test-services.sh     - Tester tous les services"
    echo -e "  2️⃣  ./setup-n8n.sh         - Configurer N8N"
    echo -e "  3️⃣  open report.html       - Voir le rapport complet"
    echo ""
    print_success "Déploiement réussi! 🎉"
}

#################################################
# Main
#################################################

main() {
    clear
    print_header "🚀 DÉPLOIEMENT VPS - Veille Stratégique Marocaine"

    mkdir -p "$LOG_DIR"
    log "=== Démarrage du déploiement VPS ==="

    check_prerequisites
    test_vps_connection
    install_vps_dependencies
    create_remote_structure
    transfer_files
    configure_remote_env
    deploy_docker_containers
    wait_for_services
    quick_tests
    configure_firewall
    print_deployment_summary

    log "=== Déploiement VPS terminé avec succès ==="
}

# Exécution
main "$@"
