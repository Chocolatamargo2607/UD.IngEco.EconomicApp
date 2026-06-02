#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# EconomicApp - Despliegue Simplificado para LXC + Docker + Tailscale
# Uso: bash deploy-lxc.sh
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# ─────────────────────── CONFIGURACIÓN ───────────────────────────────────────
APP_NAME="economicapp"
APP_PORT="5050"
GIT_REPO="https://github.com/J4F3ET/UD.IngEco.EconomicApp.git"
APP_DIR="/opt/${APP_NAME}"

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
ok() { echo -e "${GREEN}[OK]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ─────────────────────── VERIFICACIONES ──────────────────────────────────────
[[ $EUID -ne 0 ]] && err "Ejecutar como root: sudo bash $0"

command -v docker >/dev/null 2>&1 || err "Docker no está instalado"
command -v git >/dev/null 2>&1 || err "Git no está instalado"

# ─────────────────────── DESPLIEGUE ─────────────────────────────────────────
log "Iniciando despliegue de ${APP_NAME}..."

# Preparar directorio
mkdir -p ${APP_DIR}
cd ${APP_DIR}

# Clonar o actualizar repositorio
if [ -d ".git" ]; then
    log "Actualizando repositorio..."
    git pull origin main || git pull
else
    log "Clonando repositorio..."
    git clone --depth 1 ${GIT_REPO} .
fi

# Construir imagen Docker
log "Construyendo imagen Docker..."
docker build -t ${APP_NAME}:latest .

# Detener y eliminar contenedor anterior si existe
docker rm -f ${APP_NAME} 2>/dev/null || true

# Ejecutar contenedor
log "Ejecutando contenedor..."
docker run -d \
    --name ${APP_NAME} \
    --restart unless-stopped \
    -p ${APP_PORT}:5050 \
    -e ASPNETCORE_ENVIRONMENT=Production \
    ${APP_NAME}:latest

# Verificar que el contenedor esté corriendo
sleep 3
docker ps | grep -q ${APP_NAME} || err "Contenedor no iniciado"

ok "Aplicación desplegada en puerto ${APP_PORT}"

# ─────────────────────── TAILSCALE FUNNEL ────────────────────────────────────
log "Verificando Tailscale Funnel..."

# Esperar a que el puerto esté disponible
for i in {1..30}; do
    if nc -z localhost ${APP_PORT} 2>/dev/null; then
        break
    fi
    sleep 1
done

if command -v tailscale >/dev/null 2>&1; then
    if tailscale funnel status 2>/dev/null | grep -q "Funnel on"; then
        ok "Tailscale Funnel ya está activo"
    else
        log "Activando Tailscale Funnel..."
        tailscale funnel --https=443 --bg http://localhost:${APP_PORT} || true
    fi
else
    log "Tailscale no está instalado, saltando..."
fi

# ─────────────────────── RESULTADO ──────────────────────────────────────────
echo ""
ok "Despliegue completado!"
echo "  - Aplicación: http://localhost:${APP_PORT}"
echo "  - Contenedor: ${APP_NAME}"
echo '{"status":"ok"}'