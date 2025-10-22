#!/bin/bash

#################################################
# ✅ VALIDATE - Veille Stratégique Marocaine
# Valide tous les fichiers avant déploiement
#################################################

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/validation.log"
PROJECT_DIR="./veille-maroc"
REPORT_FILE="./validation-report.txt"

# Compteurs
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

#################################################
# Fonctions utilitaires
#################################################

log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${timestamp} - ${message}" >> "$LOG_FILE"
}

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    log "SUCCESS: $1"
    ((PASSED_CHECKS++))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    log "ERROR: $1"
    ((FAILED_CHECKS++))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log "WARNING: $1"
    ((WARNING_CHECKS++))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_item() {
    ((TOTAL_CHECKS++))
}

#################################################
# Validation des fichiers
#################################################

validate_file_existence() {
    print_header "Validation de l'existence des fichiers"

    local files=(
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

    cd "$PROJECT_DIR" 2>/dev/null || {
        print_error "Répertoire $PROJECT_DIR non trouvé"
        exit 1
    }

    for file in "${files[@]}"; do
        check_item
        if [ -f "$file" ] || find . -name "$file" -type f 2>/dev/null | grep -q .; then
            local file_size=$(find . -name "$file" -type f -exec ls -lh {} \; 2>/dev/null | awk '{print $5}' | head -1)
            print_success "Fichier trouvé: $file (${file_size:-unknown})"
        else
            print_error "Fichier manquant: $file"
        fi
    done

    cd ..
}

#################################################
# Validation YAML
#################################################

validate_yaml_files() {
    print_header "Validation de la syntaxe YAML"

    cd "$PROJECT_DIR"

    # Rechercher tous les fichiers YAML
    local yaml_files=$(find . -name "*.yml" -o -name "*.yaml" 2>/dev/null)

    if [ -z "$yaml_files" ]; then
        print_warning "Aucun fichier YAML trouvé"
        cd ..
        return
    fi

    for file in $yaml_files; do
        check_item
        print_info "Validation de $file..."

        # Vérifier avec Python si disponible
        if command -v python3 &> /dev/null; then
            if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>&1 | tee -a "../$LOG_FILE"; then
                print_success "YAML valide: $file"
            else
                print_error "YAML invalide: $file"
            fi
        # Sinon vérifier avec Docker si disponible
        elif command -v docker &> /dev/null; then
            if docker run --rm -v "$(pwd):/workdir" mikefarah/yq eval "$file" > /dev/null 2>&1; then
                print_success "YAML valide: $file"
            else
                print_error "YAML invalide: $file"
            fi
        else
            # Validation basique
            if grep -q "^[a-zA-Z]" "$file" && ! grep -q $'\t' "$file"; then
                print_success "YAML syntaxe basique OK: $file"
            else
                print_warning "YAML vérification basique (installez python3-yaml pour validation complète): $file"
            fi
        fi
    done

    cd ..
}

#################################################
# Validation JSON
#################################################

validate_json_files() {
    print_header "Validation de la syntaxe JSON"

    cd "$PROJECT_DIR"

    local json_files=$(find . -name "*.json" 2>/dev/null)

    if [ -z "$json_files" ]; then
        print_warning "Aucun fichier JSON trouvé"
        cd ..
        return
    fi

    for file in $json_files; do
        check_item
        print_info "Validation de $file..."

        # Vérifier avec jq si disponible
        if command -v jq &> /dev/null; then
            if jq empty "$file" 2>&1 | tee -a "../$LOG_FILE"; then
                print_success "JSON valide: $file"

                # Afficher quelques infos sur le fichier
                local keys=$(jq 'keys | length' "$file" 2>/dev/null)
                if [ ! -z "$keys" ]; then
                    print_info "  → $keys clés trouvées"
                fi
            else
                print_error "JSON invalide: $file"
            fi
        # Sinon avec Python
        elif command -v python3 &> /dev/null; then
            if python3 -m json.tool "$file" > /dev/null 2>&1; then
                print_success "JSON valide: $file"
            else
                print_error "JSON invalide: $file"
            fi
        else
            print_warning "Installez 'jq' ou 'python3' pour valider JSON: $file"
        fi
    done

    cd ..
}

#################################################
# Validation SQL
#################################################

validate_sql_files() {
    print_header "Validation des fichiers SQL"

    cd "$PROJECT_DIR"

    local sql_files=$(find . -name "*.sql" 2>/dev/null)

    if [ -z "$sql_files" ]; then
        print_warning "Aucun fichier SQL trouvé"
        cd ..
        return
    fi

    for file in $sql_files; do
        check_item
        print_info "Validation de $file..."

        # Vérifications basiques
        local errors=0

        # Vérifier la syntaxe de base
        if grep -iq "CREATE TABLE\|INSERT INTO\|SELECT\|UPDATE\|DELETE" "$file"; then
            print_success "SQL contient des commandes valides: $file"
        else
            print_warning "SQL semble vide ou invalide: $file"
            ((errors++))
        fi

        # Vérifier les points-virgules
        if grep -q ";" "$file"; then
            print_success "SQL contient des terminateurs: $file"
        else
            print_warning "SQL manque de terminateurs ';': $file"
        fi

        # Compter les tables créées
        local table_count=$(grep -ci "CREATE TABLE" "$file" 2>/dev/null || echo "0")
        print_info "  → $table_count table(s) créée(s)"

        if [ $errors -eq 0 ]; then
            print_success "SQL syntaxe basique OK: $file"
        fi
    done

    cd ..
}

#################################################
# Validation Docker
#################################################

validate_docker_files() {
    print_header "Validation des fichiers Docker"

    cd "$PROJECT_DIR"

    # Valider docker-compose.yml
    if [ -f "docker-compose.yml" ]; then
        check_item
        print_info "Validation de docker-compose.yml..."

        if command -v docker-compose &> /dev/null; then
            if docker-compose config > /dev/null 2>&1; then
                print_success "docker-compose.yml est valide"

                # Afficher les services
                local services=$(docker-compose config --services 2>/dev/null)
                if [ ! -z "$services" ]; then
                    print_info "Services définis:"
                    echo "$services" | while read service; do
                        echo "    • $service"
                    done
                fi
            else
                print_error "docker-compose.yml contient des erreurs"
                docker-compose config 2>&1 | head -10
            fi
        else
            print_warning "docker-compose non disponible pour validation"
        fi
    fi

    # Valider les Dockerfiles
    local dockerfiles=$(find . -name "Dockerfile" -o -name "*Dockerfile*" 2>/dev/null)

    for file in $dockerfiles; do
        check_item
        print_info "Validation de $file..."

        # Vérifications basiques
        if grep -q "FROM" "$file"; then
            print_success "Dockerfile contient une image de base: $file"
        else
            print_error "Dockerfile manque l'instruction FROM: $file"
        fi

        # Vérifier les bonnes pratiques
        if grep -q "WORKDIR" "$file"; then
            print_success "Dockerfile utilise WORKDIR: $file"
        else
            print_warning "Dockerfile devrait utiliser WORKDIR: $file"
        fi
    done

    cd ..
}

#################################################
# Validation .env
#################################################

validate_env_file() {
    print_header "Validation du fichier .env"

    cd "$PROJECT_DIR"

    if [ ! -f ".env" ]; then
        print_warning ".env n'existe pas encore (sera créé par setup-local.sh)"
        cd ..
        return
    fi

    check_item
    print_info "Validation de .env..."

    # Vérifier les variables critiques
    local required_vars=(
        "VPS_IP"
        "POSTGRES_PASSWORD"
        "POSTGRES_USER"
        "POSTGRES_DB"
        "OPENROUTER_API_KEY"
        "ADMIN_EMAIL"
    )

    local missing_vars=()
    for var in "${required_vars[@]}"; do
        if grep -q "^${var}=" ".env"; then
            local value=$(grep "^${var}=" ".env" | cut -d'=' -f2-)
            if [ -z "$value" ] || [ "$value" == "changeme" ]; then
                print_warning "Variable $var définie mais vide ou par défaut"
            else
                print_success "Variable $var configurée"
            fi
        else
            print_error "Variable manquante: $var"
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -eq 0 ]; then
        print_success "Toutes les variables requises sont présentes"
    else
        print_error "${#missing_vars[@]} variable(s) manquante(s)"
    fi

    # Vérifier les permissions
    local perms=$(stat -c "%a" ".env" 2>/dev/null || stat -f "%OLp" ".env" 2>/dev/null)
    if [ "$perms" == "600" ] || [ "$perms" == "400" ]; then
        print_success "Permissions .env correctes ($perms)"
    else
        print_warning "Permissions .env faibles ($perms), recommandé: 600"
    fi

    cd ..
}

#################################################
# Validation de la structure
#################################################

validate_directory_structure() {
    print_header "Validation de la structure des répertoires"

    local required_dirs=(
        "backend"
        "frontend"
        "n8n"
        "database"
    )

    cd "$PROJECT_DIR"

    for dir in "${required_dirs[@]}"; do
        check_item
        if [ -d "$dir" ] || find . -type d -name "$dir" 2>/dev/null | grep -q .; then
            print_success "Répertoire trouvé: $dir/"
        else
            print_warning "Répertoire recommandé absent: $dir/"
        fi
    done

    cd ..
}

#################################################
# Validation des dépendances Node.js
#################################################

validate_nodejs_dependencies() {
    print_header "Validation des dépendances Node.js"

    cd "$PROJECT_DIR"

    local package_files=$(find . -name "package.json" 2>/dev/null)

    if [ -z "$package_files" ]; then
        print_warning "Aucun package.json trouvé"
        cd ..
        return
    fi

    for file in $package_files; do
        check_item
        print_info "Validation de $file..."

        if command -v jq &> /dev/null; then
            local name=$(jq -r '.name // "unnamed"' "$file" 2>/dev/null)
            local version=$(jq -r '.version // "no version"' "$file" 2>/dev/null)
            local deps=$(jq '.dependencies | length' "$file" 2>/dev/null)
            local devDeps=$(jq '.devDependencies | length' "$file" 2>/dev/null)

            print_success "Package: $name@$version"
            print_info "  → $deps dépendances, $devDeps dépendances de dev"

            # Vérifier les scripts importants
            if jq -e '.scripts.start' "$file" > /dev/null 2>&1; then
                print_success "  → Script 'start' défini"
            else
                print_warning "  → Script 'start' manquant"
            fi
        else
            print_success "package.json présent: $file"
        fi
    done

    cd ..
}

#################################################
# Rapport de validation
#################################################

generate_report() {
    print_header "Génération du rapport de validation"

    cat > "$REPORT_FILE" << EOF
╔═══════════════════════════════════════════════════════════╗
║     RAPPORT DE VALIDATION - Veille Stratégique Maroc     ║
╚═══════════════════════════════════════════════════════════╝

Date: $(date '+%Y-%m-%d %H:%M:%S')
Projet: $PROJECT_DIR

═══════════════════════════════════════════════════════════

RÉSUMÉ:
-------
Total de vérifications:  $TOTAL_CHECKS
✅ Réussies:             $PASSED_CHECKS
❌ Échouées:             $FAILED_CHECKS
⚠️  Avertissements:      $WARNING_CHECKS

TAUX DE RÉUSSITE: $(awk "BEGIN {printf \"%.1f\", ($PASSED_CHECKS/$TOTAL_CHECKS)*100}")%

═══════════════════════════════════════════════════════════

STATUT GLOBAL:
EOF

    if [ $FAILED_CHECKS -eq 0 ]; then
        echo "🎉 PRÊT POUR LE DÉPLOIEMENT" >> "$REPORT_FILE"
        echo "Tous les tests critiques sont passés!" >> "$REPORT_FILE"
    elif [ $FAILED_CHECKS -le 3 ]; then
        echo "⚠️  DÉPLOIEMENT POSSIBLE AVEC PRÉCAUTIONS" >> "$REPORT_FILE"
        echo "Quelques problèmes mineurs détectés." >> "$REPORT_FILE"
    else
        echo "❌ DÉPLOIEMENT NON RECOMMANDÉ" >> "$REPORT_FILE"
        echo "Plusieurs problèmes critiques doivent être résolus." >> "$REPORT_FILE"
    fi

    cat >> "$REPORT_FILE" << EOF

═══════════════════════════════════════════════════════════

PROCHAINES ÉTAPES:

EOF

    if [ $FAILED_CHECKS -eq 0 ]; then
        cat >> "$REPORT_FILE" << EOF
✅ 1. Exécuter ./deploy-vps.sh pour déployer
✅ 2. Exécuter ./test-services.sh pour tester
✅ 3. Exécuter ./setup-n8n.sh pour configurer N8N
EOF
    else
        cat >> "$REPORT_FILE" << EOF
⚠️  1. Corriger les erreurs signalées
⚠️  2. Relancer ./validate.sh
⚠️  3. Une fois validé, lancer ./deploy-vps.sh
EOF
    fi

    cat >> "$REPORT_FILE" << EOF

═══════════════════════════════════════════════════════════

LOGS DÉTAILLÉS: $LOG_FILE

EOF

    print_success "Rapport généré: $REPORT_FILE"
}

#################################################
# Affichage du résumé
#################################################

print_summary() {
    print_header "Résumé de la validation"

    echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         RÉSULTATS DE VALIDATION       ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Total:           $TOTAL_CHECKS vérifications"
    echo -e "  ${GREEN}✅ Réussies:     $PASSED_CHECKS${NC}"
    echo -e "  ${RED}❌ Échouées:     $FAILED_CHECKS${NC}"
    echo -e "  ${YELLOW}⚠️  Avertissements: $WARNING_CHECKS${NC}"
    echo ""

    local success_rate=$(awk "BEGIN {printf \"%.1f\", ($PASSED_CHECKS/$TOTAL_CHECKS)*100}")

    if (( $(echo "$success_rate >= 90" | bc -l) )); then
        echo -e "${GREEN}🎉 Taux de réussite: $success_rate%${NC}"
        echo -e "${GREEN}✅ PRÊT POUR LE DÉPLOIEMENT!${NC}"
    elif (( $(echo "$success_rate >= 70" | bc -l) )); then
        echo -e "${YELLOW}⚠️  Taux de réussite: $success_rate%${NC}"
        echo -e "${YELLOW}⚠️  DÉPLOIEMENT POSSIBLE AVEC PRÉCAUTIONS${NC}"
    else
        echo -e "${RED}❌ Taux de réussite: $success_rate%${NC}"
        echo -e "${RED}❌ DÉPLOIEMENT NON RECOMMANDÉ${NC}"
    fi

    echo ""
    echo -e "${BLUE}📄 Rapport détaillé: $REPORT_FILE${NC}"
    echo ""
}

#################################################
# Main
#################################################

main() {
    clear
    print_header "✅ VALIDATION - Veille Stratégique Marocaine"

    mkdir -p "$LOG_DIR"
    log "=== Démarrage de la validation ==="

    # Vérifier que le projet existe
    if [ ! -d "$PROJECT_DIR" ]; then
        print_error "Répertoire $PROJECT_DIR non trouvé"
        print_info "Exécutez d'abord ./setup-local.sh"
        exit 1
    fi

    # Exécuter toutes les validations
    validate_file_existence
    validate_yaml_files
    validate_json_files
    validate_sql_files
    validate_docker_files
    validate_env_file
    validate_directory_structure
    validate_nodejs_dependencies

    # Générer le rapport
    generate_report
    print_summary

    log "=== Validation terminée ==="

    # Code de sortie basé sur les échecs
    if [ $FAILED_CHECKS -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Exécution
main "$@"
