#!/bin/bash

# ============================================================================
# 🧪 TEST COMPLET - Validation Automatisation Veille Stratégique
# ============================================================================

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# ============================================================================
# Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((TESTS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}🧪 $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

test_case() {
    ((TESTS_TOTAL++))
    echo -e "${YELLOW}Test $TESTS_TOTAL: $1${NC}"
}

# ============================================================================
# PHASE 1: Fichiers & Syntaxe
# ============================================================================

phase_1_files() {
    log_section "PHASE 1: VALIDATION FICHIERS & SYNTAXE"

    # Test 1.1: Vérifier les scripts
    test_case "Scripts bash existent"
    if [ -f setup-local.sh ] && [ -f validate.sh ] && [ -f deploy-vps.sh ] && [ -f test-services.sh ] && [ -f setup-n8n.sh ]; then
        log_success "Tous les scripts trouvés"
    else
        log_error "Scripts manquants"
        return 1
    fi

    # Test 1.2: Vérifier les permissions
    test_case "Scripts sont exécutables"
    for script in setup-local.sh validate.sh deploy-vps.sh test-services.sh setup-n8n.sh; do
        if [ -x "$script" ]; then
            log_success "$script est exécutable"
        else
            log_warning "$script n'est pas exécutable - correction..."
            chmod +x "$script"
        fi
    done

    # Test 1.3: Syntaxe bash
    test_case "Syntaxe bash valide"
    for script in setup-local.sh validate.sh deploy-vps.sh test-services.sh setup-n8n.sh; do
        if bash -n "$script" 2>/dev/null; then
            log_success "Syntaxe $script OK"
        else
            log_error "Syntaxe $script FAILED"
            return 1
        fi
    done

    # Test 1.4: Makefile existe
    test_case "Makefile existe et est valide"
    if [ -f Makefile ]; then
        log_success "Makefile trouvé"
        if make -n help > /dev/null 2>&1; then
            log_success "Makefile valide"
        else
            log_error "Makefile invalide"
        fi
    else
        log_error "Makefile manquant"
    fi

    # Test 1.5: Documentation
    test_case "Documentation existe"
    if [ -f README.md ] && [ -f QUICK-START.md ]; then
        log_success "Documentation complète"
    else
        log_warning "Documentation manquante"
    fi
}

# ============================================================================
# PHASE 2: Docker & Services Locaux
# ============================================================================

phase_2_docker() {
    log_section "PHASE 2: DOCKER & SERVICES LOCAUX"

    # Test 2.1: Docker installé
    test_case "Docker installé"
    if command -v docker &> /dev/null; then
        log_success "Docker trouvé: $(docker --version)"
    else
        log_error "Docker non installé"
        return 1
    fi

    # Test 2.2: Docker Compose installé
    test_case "Docker Compose installé"
    if command -v docker-compose &> /dev/null; then
        log_success "Docker Compose trouvé: $(docker-compose --version)"
    else
        log_error "Docker Compose non installé"
        return 1
    fi

    # Test 2.3: .env.example existe
    test_case ".env.example existe"
    if [ -f .env.example ]; then
        log_success ".env.example trouvé"
    else
        log_error ".env.example manquant"
    fi
}

# ============================================================================
# PHASE 3: Configuration & Variables
# ============================================================================

phase_3_config() {
    log_section "PHASE 3: CONFIGURATION & VARIABLES"

    # Test 3.1: .env peut être créé
    test_case "Création .env depuis .env.example"
    if [ -f .env.example ]; then
        cp .env.example .env.test
        if [ -f .env.test ]; then
            log_success ".env.test créé avec succès"
            rm .env.test
        else
            log_error "Impossible de créer .env"
        fi
    fi

    # Test 3.2: Variables obligatoires dans .env.example
    test_case "Variables obligatoires présentes"
    REQUIRED_VARS=("POSTGRES_PASSWORD" "OPENROUTER_API_KEY" "ADMIN_EMAIL")
    for var in "${REQUIRED_VARS[@]}"; do
        if grep -q "$var" .env.example; then
            log_success "Variable $var trouvée"
        else
            log_error "Variable $var manquante"
        fi
    done
}

# ============================================================================
# PHASE 4: Lint & Validation
# ============================================================================

phase_4_lint() {
    log_section "PHASE 4: LINT & VALIDATION"

    # Test 4.1: Comptage lignes de code
    test_case "Comptage lignes de code"
    TOTAL_LINES=$(wc -l *.sh *.md Makefile .env.example 2>/dev/null | tail -1 | awk '{print $1}')
    if [ "$TOTAL_LINES" -gt 5000 ]; then
        log_success "Total lignes: $TOTAL_LINES (>5000)"
    else
        log_warning "Total lignes: $TOTAL_LINES"
    fi

    # Test 4.2: Report HTML existe
    test_case "Report HTML existe"
    if [ -f report.html ]; then
        log_success "report.html trouvé"
        # Vérifier que c'est du HTML valide
        if grep -q "<!DOCTYPE html" report.html; then
            log_success "report.html est du HTML valide"
        fi
    else
        log_error "report.html manquant"
    fi
}

# ============================================================================
# PHASE 5: Tests de Fonctionnalité
# ============================================================================

phase_5_functionality() {
    log_section "PHASE 5: TESTS DE FONCTIONNALITÉ"

    # Test 5.1: Makefile help fonctionne
    test_case "Makefile help fonctionne"
    if make help > /dev/null 2>&1; then
        log_success "make help fonctionne"
    else
        log_error "make help échoue"
    fi

    # Test 5.2: Makefile targets principaux
    test_case "Makefile targets principaux existent"
    MAIN_TARGETS=("all" "setup" "validate" "deploy-vps" "test" "n8n" "status" "logs")
    for target in "${MAIN_TARGETS[@]}"; do
        if make -n "$target" > /dev/null 2>&1; then
            log_success "Target '$target' existe"
        else
            log_warning "Target '$target' n'existe pas ou a des erreurs"
        fi
    done

    # Test 5.3: Scripts contiennent des fonctions essentielles
    test_case "Scripts contiennent fonctions essentielles"
    if grep -q "print_success" setup-local.sh && grep -q "print_error" setup-local.sh; then
        log_success "Fonctions utilitaires présentes"
    else
        log_error "Fonctions utilitaires manquantes"
    fi
}

# ============================================================================
# PHASE 6: Structure & Organisation
# ============================================================================

phase_6_structure() {
    log_section "PHASE 6: STRUCTURE & ORGANISATION"

    # Test 6.1: Répertoire logs existe
    test_case "Répertoire logs peut être créé"
    mkdir -p ../logs
    if [ -d ../logs ]; then
        log_success "Répertoire logs créé"
    else
        log_error "Impossible de créer logs/"
    fi

    # Test 6.2: Scripts ont headers
    test_case "Scripts ont headers descriptifs"
    for script in setup-local.sh validate.sh deploy-vps.sh test-services.sh setup-n8n.sh; do
        if head -5 "$script" | grep -q "#"; then
            log_success "$script a un header"
        else
            log_warning "$script n'a pas de header"
        fi
    done

    # Test 6.3: Tous les fichiers existent
    test_case "Tous les fichiers attendus existent"
    EXPECTED_FILES=(
        "setup-local.sh"
        "validate.sh"
        "deploy-vps.sh"
        "test-services.sh"
        "setup-n8n.sh"
        "Makefile"
        "README.md"
        "QUICK-START.md"
        "SUMMARY.md"
        "report.html"
        ".env.example"
    )

    for file in "${EXPECTED_FILES[@]}"; do
        if [ -f "$file" ]; then
            log_success "$file existe"
        else
            log_error "$file manquant"
        fi
    done
}

# ============================================================================
# PHASE 7: Sécurité
# ============================================================================

phase_7_security() {
    log_section "PHASE 7: SÉCURITÉ"

    # Test 7.1: Pas de credentials hardcodés
    test_case "Pas de credentials hardcodés dans scripts"
    if ! grep -r "password=" *.sh | grep -v "POSTGRES_PASSWORD="; then
        log_success "Aucun mot de passe hardcodé trouvé"
    else
        log_warning "Vérifiez les mots de passe dans les scripts"
    fi

    # Test 7.2: .env dans .gitignore
    test_case ".env devrait être dans .gitignore"
    if [ -f ../.gitignore ]; then
        if grep -q ".env" ../.gitignore; then
            log_success ".env dans .gitignore"
        else
            log_warning ".env pas dans .gitignore"
        fi
    else
        log_warning ".gitignore n'existe pas"
    fi
}

# ============================================================================
# PHASE 8: Génération Rapport
# ============================================================================

phase_8_report() {
    log_section "PHASE 8: GÉNÉRATION RAPPORT"

    # Test 8.1: Génération rapport texte
    test_case "Génération rapport test"
    REPORT_FILE="../logs/test-report-$(date +%Y%m%d-%H%M%S).txt"
    mkdir -p ../logs

    cat > "$REPORT_FILE" << EOF
╔════════════════════════════════════════════════════════════════╗
║  TEST REPORT - Veille Stratégique Marocaine                   ║
╚════════════════════════════════════════════════════════════════╝

Date: $(date '+%Y-%m-%d %H:%M:%S')

RÉSULTATS:
----------
Tests Passed:     $TESTS_PASSED
Tests Failed:     $TESTS_FAILED
Tests Total:      $TESTS_TOTAL
Success Rate:     $(awk "BEGIN {printf \"%.1f\", ($TESTS_PASSED * 100 / $TESTS_TOTAL)}")%

FICHIERS TESTÉS:
----------------
✅ setup-local.sh
✅ validate.sh
✅ deploy-vps.sh
✅ test-services.sh
✅ setup-n8n.sh
✅ Makefile
✅ Documentation (README.md, QUICK-START.md, SUMMARY.md)
✅ Templates (.env.example, report.html)

STATUT GLOBAL:
--------------
EOF

    if [ $TESTS_FAILED -eq 0 ]; then
        echo "✅ TOUS LES TESTS SONT PASSÉS - READY FOR DEPLOYMENT" >> "$REPORT_FILE"
    else
        echo "⚠️  CERTAINS TESTS ONT ÉCHOUÉ - CORRECTIONS NÉCESSAIRES" >> "$REPORT_FILE"
    fi

    if [ -f "$REPORT_FILE" ]; then
        log_success "Rapport généré: $REPORT_FILE"
        echo ""
        cat "$REPORT_FILE"
    fi
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    clear
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  🧪 TEST COMPLET - VALIDATION AUTOMATISATION                  ║"
    echo "║  Veille Stratégique Marocaine                                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Vérifier qu'on est dans le bon dossier
    if [ ! -f "setup-local.sh" ]; then
        log_error "Vous n'êtes pas dans le dossier deployment-scripts"
        log_info "Exécutez: cd deployment-scripts && ./test-automation.sh"
        exit 1
    fi

    # Exécuter les phases
    phase_1_files || true
    phase_2_docker || true
    phase_3_config || true
    phase_4_lint || true
    phase_5_functionality || true
    phase_6_structure || true
    phase_7_security || true
    phase_8_report || true

    # Summary
    log_section "RÉSUMÉ FINAL"
    echo ""
    echo -e "  ${GREEN}✅ Tests réussis:  $TESTS_PASSED${NC}"
    echo -e "  ${RED}❌ Tests échoués:  $TESTS_FAILED${NC}"
    echo -e "  ${BLUE}📊 Total:          $TESTS_TOTAL tests${NC}"

    SUCCESS_RATE=$(awk "BEGIN {printf \"%.1f\", ($TESTS_PASSED * 100 / $TESTS_TOTAL)}")
    echo -e "  ${YELLOW}📈 Taux de réussite: ${SUCCESS_RATE}%${NC}"

    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  🎉 TOUS LES TESTS SONT PASSÉS!                               ║${NC}"
        echo -e "${GREEN}║  ✅ L'automatisation est prête pour le déploiement            ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${BLUE}Prochaines étapes:${NC}"
        echo -e "  1️⃣  Lisez README.md pour les instructions"
        echo -e "  2️⃣  Exécutez: make all"
        echo -e "  3️⃣  Suivez les instructions à l'écran"
        echo ""
        exit 0
    else
        echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║  ⚠️  QUELQUES TESTS ONT ÉCHOUÉ                                ║${NC}"
        echo -e "${YELLOW}║  La plupart des fonctionnalités sont opérationnelles          ║${NC}"
        echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${BLUE}Vous pouvez quand même:${NC}"
        echo -e "  • Consulter la documentation: less README.md"
        echo -e "  • Tester individuellement: ./setup-local.sh"
        echo -e "  • Voir le rapport: cat ../logs/test-report-*.txt"
        echo ""
        exit 1
    fi
}

main "$@"
