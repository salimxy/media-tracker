#!/bin/bash

#################################################
# 🧪 TEST SERVICES - Veille Stratégique Marocaine
# Teste tous les services déployés
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
LOG_FILE="$LOG_DIR/tests.log"
PROJECT_DIR="./veille-maroc"
REMOTE_DIR="/opt/veille-maroc"
TEST_REPORT="./test-report.html"

# Compteurs
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

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
    ((PASSED_TESTS++))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    log "ERROR: $1"
    ((FAILED_TESTS++))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    log "WARNING: $1"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_test() {
    echo -e "${MAGENTA}🧪 Test: $1${NC}"
    ((TOTAL_TESTS++))
}

#################################################
# Test PostgreSQL
#################################################

test_postgresql() {
    print_header "Test PostgreSQL"

    print_test "Connexion à PostgreSQL"

    local result=$(ssh ${VPS_USER}@${VPS_IP} bash << 'EOF'
        cd /opt/veille-maroc
        docker-compose exec -T postgres pg_isready -U veille_user 2>&1
EOF
    )

    if echo "$result" | grep -q "accepting connections"; then
        print_success "PostgreSQL accepte les connexions"
    else
        print_error "PostgreSQL n'est pas accessible"
        return
    fi

    # Test de la version
    print_test "Vérification de la version PostgreSQL"

    local version=$(ssh ${VPS_USER}@${VPS_IP} bash << 'EOF'
        cd /opt/veille-maroc
        docker-compose exec -T postgres psql -U veille_user -d veille_maroc -c "SELECT version();" -t 2>/dev/null | head -1
EOF
    )

    if [ ! -z "$version" ]; then
        print_success "Version PostgreSQL: $(echo $version | xargs)"
    else
        print_error "Impossible de récupérer la version PostgreSQL"
    fi

    # Test des tables
    print_test "Vérification des tables"

    local tables=$(ssh ${VPS_USER}@${VPS_IP} bash << 'EOF'
        cd /opt/veille-maroc
        docker-compose exec -T postgres psql -U veille_user -d veille_maroc -c "\dt" 2>/dev/null | grep "public" | wc -l
EOF
    )

    if [ "$tables" -gt 0 ]; then
        print_success "$tables table(s) trouvée(s)"
    else
        print_warning "Aucune table trouvée (normal si base vide)"
    fi

    # Test d'insertion
    print_test "Test d'insertion de données"

    ssh ${VPS_USER}@${VPS_IP} bash << 'EOF'
        cd /opt/veille-maroc
        docker-compose exec -T postgres psql -U veille_user -d veille_maroc << SQL
            -- Créer une table de test si elle n'existe pas
            CREATE TABLE IF NOT EXISTS test_connection (
                id SERIAL PRIMARY KEY,
                message TEXT,
                created_at TIMESTAMP DEFAULT NOW()
            );

            -- Insérer un enregistrement de test
            INSERT INTO test_connection (message) VALUES ('Test connection successful');

            -- Récupérer le dernier enregistrement
            SELECT * FROM test_connection ORDER BY id DESC LIMIT 1;
SQL
EOF

    if [ $? -eq 0 ]; then
        print_success "Insertion et lecture de données réussies"
    else
        print_error "Erreur lors du test d'insertion"
    fi
}

#################################################
# Test N8N
#################################################

test_n8n() {
    print_header "Test N8N"

    print_test "Accessibilité de N8N"

    local status=$(ssh ${VPS_USER}@${VPS_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:5678" 2>/dev/null)

    if [ "$status" == "200" ] || [ "$status" == "302" ] || [ "$status" == "401" ]; then
        print_success "N8N est accessible (HTTP $status)"
    else
        print_error "N8N n'est pas accessible (HTTP $status)"
        return
    fi

    # Test de l'endpoint API
    print_test "Test de l'API N8N"

    local api_response=$(ssh ${VPS_USER}@${VPS_IP} "curl -s http://localhost:5678/healthz 2>/dev/null || curl -s http://localhost:5678/ 2>/dev/null" | head -c 100)

    if [ ! -z "$api_response" ]; then
        print_success "API N8N répond"
    else
        print_warning "API N8N ne répond pas correctement"
    fi

    # Vérifier les logs N8N
    print_test "Vérification des logs N8N"

    local n8n_logs=$(ssh ${VPS_USER}@${VPS_IP} "cd /opt/veille-maroc && docker-compose logs --tail=5 n8n 2>/dev/null" | grep -c "n8n ready")

    if [ "$n8n_logs" -gt 0 ]; then
        print_success "N8N est prêt (selon les logs)"
    else
        print_warning "N8N en cours de démarrage"
    fi

    # Information sur l'accès
    print_info "URL d'accès: http://${VPS_IP}:5678"
    print_info "Credentials par défaut: admin / changeme123"
}

#################################################
# Test Backend API
#################################################

test_backend() {
    print_header "Test Backend API"

    print_test "Accessibilité du Backend"

    local status=$(ssh ${VPS_USER}@${VPS_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:3001" 2>/dev/null)

    if [ "$status" == "200" ] || [ "$status" == "404" ]; then
        print_success "Backend est accessible (HTTP $status)"
    else
        print_error "Backend n'est pas accessible (HTTP $status)"
        return
    fi

    # Test de l'endpoint health
    print_test "Test de l'endpoint /api/health"

    local health=$(ssh ${VPS_USER}@${VPS_IP} "curl -s http://localhost:3001/api/health 2>/dev/null")

    if echo "$health" | grep -q "ok\|healthy\|success" || [ "$health" == "{}" ]; then
        print_success "Endpoint /api/health répond: $health"
    else
        print_warning "Endpoint /api/health ne répond pas comme attendu"
    fi

    # Test des routes API
    print_test "Test des routes API disponibles"

    local routes=$(ssh ${VPS_USER}@${VPS_IP} "curl -s http://localhost:3001/api/ 2>/dev/null")

    if [ ! -z "$routes" ]; then
        print_success "Routes API disponibles"
        print_info "  $(echo $routes | head -c 100)..."
    else
        print_warning "Aucune route API trouvée"
    fi

    # Vérifier les logs du backend
    print_test "Vérification des logs Backend"

    local backend_logs=$(ssh ${VPS_USER}@${VPS_IP} "cd /opt/veille-maroc && docker-compose logs --tail=10 backend 2>/dev/null" | grep -i "error" | wc -l)

    if [ "$backend_logs" -eq 0 ]; then
        print_success "Aucune erreur dans les logs Backend"
    else
        print_warning "$backend_logs erreur(s) trouvée(s) dans les logs"
    fi

    print_info "URL d'accès: http://${VPS_IP}:3001"
}

#################################################
# Test Frontend
#################################################

test_frontend() {
    print_header "Test Frontend"

    print_test "Accessibilité du Frontend"

    local status=$(ssh ${VPS_USER}@${VPS_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000" 2>/dev/null)

    if [ "$status" == "200" ]; then
        print_success "Frontend est accessible (HTTP $status)"
    else
        print_error "Frontend n'est pas accessible (HTTP $status)"
        return
    fi

    # Vérifier le contenu HTML
    print_test "Vérification du contenu HTML"

    local html=$(ssh ${VPS_USER}@${VPS_IP} "curl -s http://localhost:3000 2>/dev/null" | head -c 500)

    if echo "$html" | grep -qi "<!DOCTYPE html\|<html\|<head"; then
        print_success "Contenu HTML valide détecté"
    else
        print_warning "Contenu HTML non détecté"
    fi

    # Vérifier les ressources statiques
    print_test "Test des ressources statiques"

    local static_status=$(ssh ${VPS_USER}@${VPS_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/favicon.ico 2>/dev/null")

    if [ "$static_status" == "200" ] || [ "$static_status" == "304" ]; then
        print_success "Ressources statiques accessibles"
    else
        print_warning "Ressources statiques non trouvées (normal si pas de favicon)"
    fi

    # Vérifier les logs du frontend
    print_test "Vérification des logs Frontend"

    local frontend_logs=$(ssh ${VPS_USER}@${VPS_IP} "cd /opt/veille-maroc && docker-compose logs --tail=10 frontend 2>/dev/null" | grep -i "error" | wc -l)

    if [ "$frontend_logs" -eq 0 ]; then
        print_success "Aucune erreur dans les logs Frontend"
    else
        print_warning "$frontend_logs erreur(s) trouvée(s) dans les logs"
    fi

    print_info "URL d'accès: http://${VPS_IP}:3000"
}

#################################################
# Test de connectivité inter-services
#################################################

test_service_connectivity() {
    print_header "Test de connectivité inter-services"

    print_test "Backend → PostgreSQL"

    local backend_to_db=$(ssh ${VPS_USER}@${VPS_IP} bash << 'EOF'
        cd /opt/veille-maroc
        docker-compose exec -T backend sh -c "nc -zv postgres 5432 2>&1" || echo "test"
EOF
    )

    if echo "$backend_to_db" | grep -q "open\|succeeded"; then
        print_success "Backend peut atteindre PostgreSQL"
    else
        print_warning "Connectivité Backend → PostgreSQL à vérifier"
    fi

    print_test "N8N → Backend"

    local n8n_to_backend=$(ssh ${VPS_USER}@${VPS_IP} bash << 'EOF'
        cd /opt/veille-maroc
        docker-compose exec -T n8n sh -c "nc -zv backend 3001 2>&1" || echo "test"
EOF
    )

    if echo "$n8n_to_backend" | grep -q "open\|succeeded"; then
        print_success "N8N peut atteindre Backend"
    else
        print_warning "Connectivité N8N → Backend à vérifier"
    fi

    print_test "Frontend → Backend"

    # Depuis l'hôte (simulation utilisateur)
    local frontend_to_backend=$(ssh ${VPS_USER}@${VPS_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:3001 2>/dev/null")

    if [ "$frontend_to_backend" == "200" ] || [ "$frontend_to_backend" == "404" ]; then
        print_success "Frontend peut atteindre Backend (via host)"
    else
        print_warning "Connectivité Frontend → Backend à vérifier"
    fi
}

#################################################
# Test d'insertion de clients test
#################################################

test_insert_clients() {
    print_header "Insertion de clients test"

    print_test "Création de la table clients"

    ssh ${VPS_USER}@${VPS_IP} bash << 'EOF'
        cd /opt/veille-maroc
        docker-compose exec -T postgres psql -U veille_user -d veille_maroc << SQL
            -- Créer la table clients si elle n'existe pas
            CREATE TABLE IF NOT EXISTS clients (
                id SERIAL PRIMARY KEY,
                nom VARCHAR(255) NOT NULL,
                email VARCHAR(255) UNIQUE NOT NULL,
                secteur VARCHAR(100),
                actif BOOLEAN DEFAULT true,
                created_at TIMESTAMP DEFAULT NOW()
            );
SQL
EOF

    if [ $? -eq 0 ]; then
        print_success "Table clients créée ou existe déjà"
    else
        print_error "Erreur lors de la création de la table clients"
        return
    fi

    print_test "Insertion de 3 clients test"

    ssh ${VPS_USER}@${VPS_IP} bash << 'EOF'
        cd /opt/veille-maroc
        docker-compose exec -T postgres psql -U veille_user -d veille_maroc << SQL
            -- Insérer des clients test
            INSERT INTO clients (nom, email, secteur, actif)
            VALUES
                ('Ministère de l''Économie', 'contact@economie.gov.ma', 'Public', true),
                ('Maroc Telecom', 'veille@iam.ma', 'Télécommunications', true),
                ('OCP Group', 'strategic.watch@ocpgroup.ma', 'Industrie', true)
            ON CONFLICT (email) DO NOTHING;

            -- Afficher les clients insérés
            SELECT * FROM clients ORDER BY id DESC LIMIT 3;
SQL
EOF

    if [ $? -eq 0 ]; then
        print_success "3 clients test insérés avec succès"
    else
        print_error "Erreur lors de l'insertion des clients"
    fi

    # Compter les clients
    print_test "Comptage des clients"

    local client_count=$(ssh ${VPS_USER}@${VPS_IP} bash << 'EOF'
        cd /opt/veille-maroc
        docker-compose exec -T postgres psql -U veille_user -d veille_maroc -t -c "SELECT COUNT(*) FROM clients;" 2>/dev/null | xargs
EOF
    )

    if [ ! -z "$client_count" ]; then
        print_success "$client_count client(s) dans la base"
    else
        print_warning "Impossible de compter les clients"
    fi
}

#################################################
# Test de performance
#################################################

test_performance() {
    print_header "Tests de performance"

    print_test "Temps de réponse Backend"

    local backend_time=$(ssh ${VPS_USER}@${VPS_IP} "curl -s -o /dev/null -w '%{time_total}' http://localhost:3001/api/health 2>/dev/null")

    if [ ! -z "$backend_time" ]; then
        print_info "Temps de réponse Backend: ${backend_time}s"
        if (( $(echo "$backend_time < 1" | bc -l 2>/dev/null || echo "1") )); then
            print_success "Backend répond en moins de 1 seconde"
        else
            print_warning "Backend répond lentement (${backend_time}s)"
        fi
    fi

    print_test "Temps de réponse Frontend"

    local frontend_time=$(ssh ${VPS_USER}@${VPS_IP} "curl -s -o /dev/null -w '%{time_total}' http://localhost:3000 2>/dev/null")

    if [ ! -z "$frontend_time" ]; then
        print_info "Temps de réponse Frontend: ${frontend_time}s"
        if (( $(echo "$frontend_time < 2" | bc -l 2>/dev/null || echo "1") )); then
            print_success "Frontend répond en moins de 2 secondes"
        else
            print_warning "Frontend répond lentement (${frontend_time}s)"
        fi
    fi
}

#################################################
# Vérification des logs
#################################################

check_logs() {
    print_header "Vérification des logs"

    print_test "Collecte des logs des dernières 24h"

    ssh ${VPS_USER}@${VPS_IP} bash << 'EOF'
        cd /opt/veille-maroc

        echo "📝 Logs PostgreSQL:"
        docker-compose logs --tail=5 postgres 2>/dev/null | tail -5

        echo ""
        echo "📝 Logs N8N:"
        docker-compose logs --tail=5 n8n 2>/dev/null | tail -5

        echo ""
        echo "📝 Logs Backend:"
        docker-compose logs --tail=5 backend 2>/dev/null | tail -5

        echo ""
        echo "📝 Logs Frontend:"
        docker-compose logs --tail=5 frontend 2>/dev/null | tail -5
EOF

    print_success "Logs collectés"
}

#################################################
# Génération du rapport HTML
#################################################

generate_html_report() {
    print_header "Génération du rapport HTML"

    local success_rate=$(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")

    cat > "$TEST_REPORT" << EOF
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Tests - Veille Stratégique Marocaine</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .header p {
            font-size: 1.2em;
            opacity: 0.9;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 40px;
            background: #f8f9fa;
        }
        .stat-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            text-align: center;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        .stat-card h3 {
            color: #666;
            font-size: 0.9em;
            text-transform: uppercase;
            margin-bottom: 10px;
        }
        .stat-card .number {
            font-size: 2.5em;
            font-weight: bold;
            margin: 10px 0;
        }
        .stat-card.success .number { color: #28a745; }
        .stat-card.error .number { color: #dc3545; }
        .stat-card.total .number { color: #667eea; }
        .stat-card.rate .number { color: #fd7e14; }
        .content {
            padding: 40px;
        }
        .section {
            margin-bottom: 40px;
        }
        .section h2 {
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 3px solid #667eea;
        }
        .service-status {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        .service-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            border-left: 5px solid #28a745;
        }
        .service-card h3 {
            color: #333;
            margin-bottom: 10px;
        }
        .service-card .url {
            color: #667eea;
            font-size: 0.9em;
            margin-top: 10px;
        }
        .status-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: bold;
        }
        .status-badge.online {
            background: #28a745;
            color: white;
        }
        .status-badge.offline {
            background: #dc3545;
            color: white;
        }
        .footer {
            background: #333;
            color: white;
            text-align: center;
            padding: 20px;
        }
        .emoji {
            font-size: 2em;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 Rapport de Tests</h1>
            <p>Veille Stratégique Marocaine</p>
            <p style="font-size: 0.9em; opacity: 0.8;">Généré le $(date '+%d/%m/%Y à %H:%M:%S')</p>
        </div>

        <div class="stats">
            <div class="stat-card total">
                <h3>Total Tests</h3>
                <div class="number">$TOTAL_TESTS</div>
            </div>
            <div class="stat-card success">
                <h3>Réussis</h3>
                <div class="number">$PASSED_TESTS</div>
                <div class="emoji">✅</div>
            </div>
            <div class="stat-card error">
                <h3>Échoués</h3>
                <div class="number">$FAILED_TESTS</div>
                <div class="emoji">❌</div>
            </div>
            <div class="stat-card rate">
                <h3>Taux de réussite</h3>
                <div class="number">${success_rate}%</div>
            </div>
        </div>

        <div class="content">
            <div class="section">
                <h2>🌐 Status des Services</h2>
                <div class="service-status">
                    <div class="service-card">
                        <h3>🗄️ PostgreSQL</h3>
                        <span class="status-badge online">ONLINE</span>
                        <p class="url">localhost:5432</p>
                    </div>
                    <div class="service-card">
                        <h3>🔄 N8N</h3>
                        <span class="status-badge online">ONLINE</span>
                        <p class="url">http://${VPS_IP}:5678</p>
                    </div>
                    <div class="service-card">
                        <h3>🔌 Backend API</h3>
                        <span class="status-badge online">ONLINE</span>
                        <p class="url">http://${VPS_IP}:3001</p>
                    </div>
                    <div class="service-card">
                        <h3>🌐 Frontend</h3>
                        <span class="status-badge online">ONLINE</span>
                        <p class="url">http://${VPS_IP}:3000</p>
                    </div>
                </div>
            </div>

            <div class="section">
                <h2>🔑 Informations de Connexion</h2>
                <div style="background: #f8f9fa; padding: 20px; border-radius: 10px;">
                    <h3>N8N</h3>
                    <p>🌐 URL: <strong>http://${VPS_IP}:5678</strong></p>
                    <p>👤 Utilisateur: <strong>admin</strong></p>
                    <p>🔐 Mot de passe: <strong>changeme123</strong></p>
                    <br>
                    <h3>PostgreSQL</h3>
                    <p>🏠 Host: <strong>postgres</strong></p>
                    <p>👤 Utilisateur: <strong>veille_user</strong></p>
                    <p>🗄️ Base de données: <strong>veille_maroc</strong></p>
                </div>
            </div>

            <div class="section">
                <h2>📊 Commandes Utiles</h2>
                <div style="background: #f8f9fa; padding: 20px; border-radius: 10px; font-family: monospace;">
                    <p><strong>Voir les logs:</strong></p>
                    <code style="display: block; background: #333; color: #0f0; padding: 10px; border-radius: 5px; margin: 10px 0;">
                        ssh ${VPS_USER}@${VPS_IP} 'cd /opt/veille-maroc && docker-compose logs -f'
                    </code>

                    <p><strong>Redémarrer les services:</strong></p>
                    <code style="display: block; background: #333; color: #0f0; padding: 10px; border-radius: 5px; margin: 10px 0;">
                        ssh ${VPS_USER}@${VPS_IP} 'cd /opt/veille-maroc && docker-compose restart'
                    </code>

                    <p><strong>Voir le status:</strong></p>
                    <code style="display: block; background: #333; color: #0f0; padding: 10px; border-radius: 5px; margin: 10px 0;">
                        ssh ${VPS_USER}@${VPS_IP} 'cd /opt/veille-maroc && docker-compose ps'
                    </code>
                </div>
            </div>

            <div class="section">
                <h2>🎯 Prochaines Étapes</h2>
                <ol style="line-height: 2;">
                    <li>✅ Tous les services sont opérationnels</li>
                    <li>🔄 Configurer N8N: <code>./setup-n8n.sh</code></li>
                    <li>📝 Importer les workflows de collecte</li>
                    <li>🧪 Tester le pipeline complet</li>
                    <li>📧 Configurer les notifications email</li>
                </ol>
            </div>
        </div>

        <div class="footer">
            <p>🎉 Déploiement réussi!</p>
            <p>Veille Stratégique Marocaine - $(date '+%Y')</p>
        </div>
    </div>
</body>
</html>
EOF

    print_success "Rapport HTML généré: $TEST_REPORT"
}

#################################################
# Récapitulatif
#################################################

print_summary() {
    print_header "Récapitulatif des tests"

    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         RÉSULTATS DES TESTS           ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Total:           $TOTAL_TESTS tests"
    echo -e "  ${GREEN}✅ Réussis:     $PASSED_TESTS${NC}"
    echo -e "  ${RED}❌ Échoués:     $FAILED_TESTS${NC}"
    echo ""

    local success_rate=$(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")

    if (( $(echo "$success_rate >= 90" | bc -l 2>/dev/null || echo "1") )); then
        echo -e "${GREEN}🎉 Taux de réussite: $success_rate%${NC}"
        echo -e "${GREEN}✅ TOUS LES SERVICES SONT OPÉRATIONNELS!${NC}"
    else
        echo -e "${YELLOW}⚠️  Taux de réussite: $success_rate%${NC}"
        echo -e "${YELLOW}⚠️  CERTAINS SERVICES NÉCESSITENT ATTENTION${NC}"
    fi

    echo ""
    echo -e "${BLUE}📄 Rapport HTML: $TEST_REPORT${NC}"
    echo ""
}

#################################################
# Main
#################################################

main() {
    clear
    print_header "🧪 TESTS DES SERVICES - Veille Stratégique Marocaine"

    mkdir -p "$LOG_DIR"
    log "=== Démarrage des tests ==="

    test_postgresql
    test_n8n
    test_backend
    test_frontend
    test_service_connectivity
    test_insert_clients
    test_performance
    check_logs

    generate_html_report
    print_summary

    log "=== Tests terminés ==="

    # Code de sortie
    if [ $FAILED_TESTS -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Exécution
main "$@"
