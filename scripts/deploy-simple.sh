#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# EconomicApp - Despliegue Rápido para LXC + Tailscale
# Usage: curl -fsSL https://raw.githubusercontent.com/J4F3ET/EconomicApp/main/scripts/deploy.sh | bash -s -- --repo YOUR_REPO --branch main
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# ─────────────────────── CONFIGURACIÓN ───────────────────────────────────────
APP_NAME="EconomicApp"
APP_PORT="5050"
GIT_REPO="${REPO_URL:-https://github.com/J4F3ET/EconomicApp.git}"
BRANCH="${BRANCH_NAME:-main}"
APP_DIR="/opt/economicapp"
BUILD_DIR="${APP_DIR}/bin/publish"
SERVICE_NAME="economicapp"

# Colores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# ─────────────────────── HELP ────────────────────────────────────────────────
show_help() {
    cat << 'HELP'
Usage: deploy.sh [OPTIONS]

Opciones:
    --repo URL       URL del repositorio Git (default: config inline)
    --branch NAME    Rama de Git (default: main)
    --docker        Usar Docker en lugar de .NET directo
    --update        Solo actualizar código y recompilar
    --status        Ver estado del servicio
    --logs          Ver logs en tiempo real
    --uninstall     Desinstalar aplicación
    --help          Mostrar esta ayuda

Ejemplos:
    # Despliegue completo
    ./deploy.sh --repo https://github.com/user/EconomicApp.git

    # Solo actualizar
    ./deploy.sh --update

    # Ver estado
    ./deploy.sh --status
HELP
}

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1"; }

# ─────────────────────── VERIFICACIONES ──────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    log_err "Ejecutar como root: sudo $0 $@"
    exit 1
fi

# ─────────────────────── PARSEO DE ARGUMENTOS ────────────────────────────────
MODE="install"
while [[ $# -gt 0 ]]; do
    case $1 in
        --repo) GIT_REPO="$2"; shift 2 ;;
        --branch) BRANCH="$2"; shift 2 ;;
        --docker) USE_DOCKER=1; shift ;;
        --update) MODE="update"; shift ;;
        --status) MODE="status"; shift ;;
        --logs) MODE="logs"; shift ;;
        --uninstall) MODE="uninstall"; shift ;;
        --help) show_help; exit 0 ;;
        *) shift ;;
    esac
done

# ─────────────────────── FUNCIÓN: INSTALAR DEPENDENCIAS ──────────────────────
install_deps() {
    log "Actualizando sistema..."
    apt update && apt upgrade -y

    log "Instalando .NET SDK 8..."
    wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O /tmp/ms-prod.deb
    dpkg -i /tmp/ms-prod.deb
    rm /tmp/ms-prod.deb
    apt update
    apt install -y dotnet-sdk-8.0

    log "Instalando herramientas..."
    apt install -y git curl ufw
}

# ─────────────────────── FUNCIÓN: DESPLIEGUE ─────────────────────────────────
deploy() {
    log "Preparando directorio de trabajo..."
    mkdir -p ${APP_DIR}
    cd ${APP_DIR}

    if [ -d ".git" ]; then
        log "Actualizando repositorio existente..."
        git fetch origin
        git checkout ${BRANCH}
        git pull origin ${BRANCH}
    else
        log "Clonando repositorio..."
        git clone -b ${BRANCH} --depth 1 ${GIT_REPO} ${APP_DIR}
    fi

    log "Compilando aplicación..."
    dotnet publish -c Release -o ${BUILD_DIR} --no-restore

    log "Configurando servicio systemd..."
    cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=EconomicApp - Simulador de Créditos Académico
Documentation=https://github.com/J4F3ET/EconomicApp
After=network.target
Wants=network.target

[Service]
Type=simple
WorkingDirectory=${BUILD_DIR}
ExecStart=/usr/bin/dotnet ${BUILD_DIR}/EconomicApp.dll
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}

Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://localhost:${APP_PORT}

# Seguridad
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

    log "Habilitando servicio..."
    systemctl daemon-reload
    systemctl enable ${SERVICE_NAME}
    systemctl stop ${SERVICE_NAME} 2>/dev/null || true
    systemctl start ${SERVICE_NAME}

    # Esperar y verificar
    sleep 3
    if systemctl is-active --quiet ${SERVICE_NAME}; then
        log_ok "Servicio iniciado correctamente"
        log_ok "Aplicación corriendo en: http://localhost:${APP_PORT}"
    else
        log_err "El servicio no pudo iniciar"
        journalctl -u ${SERVICE_NAME} -n 10 --no-pager
    fi
}

# ─────────────────────── FUNCIÓN: VERIFICAR ──────────────────────────────────
check_status() {
    echo ""
    echo "═══════════════════════════════════════════════"
    echo "         EconomicApp - Estado del Servicio"
    echo "═══════════════════════════════════════════════"
    echo ""

    if systemctl is-active --quiet ${SERVICE_NAME}; then
        log_ok "Estado: ACTIVO"
        echo ""
        echo "Proceso:"
        ps aux | grep "[E]conomicApp" || true
        echo ""
        echo "Puerto escuchando:"
        ss -tlnp | grep ${APP_PORT} || netstat -tlnp | grep ${APP_PORT} || log_warn "Puerto no encontrado"
        echo ""
        echo "Memoria usada:"
        systemctl show ${SERVICE_NAME} --property=MemoryCurrent --no-pager
    else
        log_err "Estado: INACTIVO"
        log "Intentando reiniciar..."
        systemctl restart ${SERVICE_NAME}
        sleep 2
        if systemctl is-active --quiet ${SERVICE_NAME}; then
            log_ok "Reiniciado exitosamente"
        else
            log_err "No se pudo iniciar. Logs:"
            journalctl -u ${SERVICE_NAME} -n 15 --no-pager
        fi
    fi
}

# ─────────────────────── FUNCIÓN: VER LOGS ───────────────────────────────────
show_logs() {
    journalctl -u ${SERVICE_NAME} -n 100 --no-pager -f
}

# ─────────────────────── FUNCIÓN: DESINSTALAR ───────────────────────────────
uninstall() {
    log "Deteniendo servicio..."
    systemctl stop ${SERVICE_NAME} 2>/dev/null || true
    systemctl disable ${SERVICE_NAME} 2>/dev/null || true
    
    log "Eliminando archivos..."
    rm -rf /opt/economicapp
    rm -f /etc/systemd/system/${SERVICE_NAME}.service
    systemctl daemon-reload
    
    log_ok "Aplicación desinstalada"
}

# ─────────────────────── EJECUTAR SEGÚN MODO ────────────────────────────────
case $MODE in
    install)
        log "Iniciando despliegue de EconomicApp..."
        install_deps
        deploy
        check_status
        ;;
    update)
        log "Actualizando aplicación..."
        cd ${APP_DIR}
        git pull origin ${BRANCH}
        dotnet publish -c Release -o ${BUILD_DIR} --no-restore
        systemctl restart ${SERVICE_NAME}
        log_ok "Actualización completada"
        ;;
    status)
        check_status
        ;;
    logs)
        show_logs
        ;;
    uninstall)
        uninstall
        ;;
esac

echo ""
log "Script completado: $(date)"