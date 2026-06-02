# EconomicApp - Tailscale Deploy Script
# =============================================================================
# Requirements: Ubuntu 22.04+ en LXC, acceso Tailscale
# =============================================================================

#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN - EDITAR ANTES DE EJECUTAR
# ═══════════════════════════════════════════════════════════════════════════════
GIT_REPO="https://github.com/J4F3ET/EconomicApp.git"
BRANCH="main"
PORT=5050

# ═══════════════════════════════════════════════════════════════════════════════
# COLORS
# ═══════════════════════════════════════════════════════════════════════════════
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
ok() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[✗]${NC} $1"; }

# ═══════════════════════════════════════════════════════════════════════════════
# VERIFICAR ROOT
# ═══════════════════════════════════════════════════════════════════════════════
if [[ $EUID -ne 0 ]]; then
    err "Ejecutar como root: sudo $0 $@"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════════
# PASO 1: INSTALAR DEPENDENCIAS
# ═══════════════════════════════════════════════════════════════════════════════
install_deps() {
    log "─────────────────────────────────────────"
    log "  PASO 1: Instalando dependencias"
    log "─────────────────────────────────────────"
    
    apt update && apt upgrade -y
    
    # .NET SDK 8
    log "Instalando .NET SDK 8..."
    wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O /tmp/ms-prod.deb
    dpkg -i /tmp/ms-prod.deb
    rm /tmp/ms-prod.deb
    apt update
    apt install -y dotnet-sdk-8.0
    
    ok "Dependencias instaladas"
}

# ═══════════════════════════════════════════════════════════════════════════════
# PASO 2: CONFIGURAR TAILSCALE
# ═══════════════════════════════════════════════════════════════════════════════
setup_tailscale() {
    log "─────────────────────────────────────────"
    log "  PASO 2: Configurando Tailscale"
    log "─────────────────────────────────────────"
    
    # Instalar Tailscale
    curl -fsSL https://tailscale.com/install.sh | sh
    
    # Solicitar autenticación
    echo ""
    warn "Necesitas autenticarte en Tailscale"
    echo "Ejecuta: tailscale up --operator=root"
    echo ""
    read -p "Presiona ENTER cuando hayas completado la autenticación..."
    
    # Verificar conexión
    if tailscale status &>/dev/null; then
        IP=$(tailscale ip -4)
        ok "Tailscale conectado. IP: $IP"
    else
        err "Tailscale no está conectado"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# PASO 3: DESPLIEGUE
# ═══════════════════════════════════════════════════════════════════════════════
deploy_app() {
    log "─────────────────────────────────────────"
    log "  PASO 3: Desplegando EconomicApp"
    log "─────────────────────────────────────────"
    
    APP_DIR="/opt/economicapp"
    mkdir -p ${APP_DIR}
    
    # Clonar o actualizar
    if [ -d "${APP_DIR}/.git" ]; then
        log "Actualizando repositorio..."
        cd ${APP_DIR}
        git pull origin ${BRANCH}
    else
        log "Clonando repositorio..."
        git clone -b ${BRANCH} --depth 1 ${GIT_REPO} ${APP_DIR}
    fi
    
    # Compilar
    log "Compilando aplicación..."
    cd ${APP_DIR}
    dotnet publish -c Release -o ${APP_DIR}/publish --no-restore
    
    # Servicio systemd
    log "Creando servicio systemd..."
    cat > /etc/systemd/system/economicapp.service << EOF
[Unit]
Description=EconomicApp - Simulador de Créditos Académico
After=network.target tailscaled.service
Wants=network.target

[Service]
Type=simple
WorkingDirectory=${APP_DIR}/publish
ExecStart=/usr/bin/dotnet ${APP_DIR}/publish/EconomicApp.dll
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=economicapp

Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://+:${PORT}
Environment=DOTNET_GCHeapHardLimit=100000000

# Seguridad Linux
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
ReadWritePaths=${APP_DIR}

[Install]
WantedBy=multi-user.target
EOF

    # Habilitar
    systemctl daemon-reload
    systemctl enable economicapp
    systemctl start economicapp
    
    sleep 2
    
    if systemctl is-active --quiet economicapp; then
        ok "Servicio iniciado"
    else
        err "Error al iniciar servicio"
        journalctl -u economicapp -n 10 --no-pager
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# PASO 4: VERIFICACIÓN FINAL
# ═══════════════════════════════════════════════════════════════════════════════
verify() {
    log "─────────────────────────────────────────"
    log "  PASO 4: Verificación final"
    log "─────────────────────────────────────────"
    
    echo ""
    echo "┌─────────────────────────────────────────┐"
    echo "│         EconomicApp - Resumen          │"
    echo "└─────────────────────────────────────────┘"
    echo ""
    
    # Estado del servicio
    if systemctl is-active --quiet economicapp; then
        ok "Servicio: ACTIVO"
    else
        err "Servicio: INACTIVO"
    fi
    
    # Puerto
    if ss -tlnp 2>/dev/null | grep -q ":${PORT}"; then
        ok "Puerto ${PORT}: LISTENING"
    elif netstat -tlnp 2>/dev/null | grep -q ":${PORT}"; then
        ok "Puerto ${PORT}: LISTENING"
    else
        warn "Puerto ${PORT}: No escuchando aún"
    fi
    
    # Tailscale
    if command -v tailscale &>/dev/null && tailscale status &>/dev/null; then
        IP=$(tailscale ip -4 2>/dev/null || echo "N/A")
        ok "Tailscale IP: ${IP}"
    else
        warn "Tailscale: No conectado"
    fi
    
    echo ""
    echo "─────────────────────────────────────────"
    echo "  ACCESO"
    echo "─────────────────────────────────────────"
    echo ""
    echo "  Local:  http://localhost:${PORT}"
    echo "  Tailscale: http://$(tailscale ip -4 2>/dev/null || echo '<TAILSCALE_IP>'):${PORT}"
    echo ""
    echo "  Comandos útiles:"
    echo "    • systemctl status economicapp    (ver estado)"
    echo "    • journalctl -u economicapp -f   (ver logs)"
    echo "    • systemctl restart economicapp (reiniciar)"
    echo ""
    echo "  Para actualizar:"
    echo "    cd /opt/economicapp && git pull && dotnet publish -c Release -o publish"
    echo "    systemctl restart economicapp"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# EJECUCIÓN PRINCIPAL
# ═══════════════════════════════════════════════════════════════════════════════
main() {
    clear
    echo ""
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║     EconomicApp - Despliegue para LXC + Tailscale    ║"
    echo "║                                                   ║"
    echo "║     .NET 8 + Blazor Server + Tailwind CSS         ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo ""
    
    install_deps
    deploy_app
    verify
    
    ok "¡Despliegue completado!"
}

main "$@"