#!/bin/bash
# EconomicApp Deployment Script
# Designed for LXC with Tailscale networking

set -e

# ==================== CONFIGURACIÓN ====================
APP_NAME="EconomicApp"
APP_PORT="5050"
TAILSCALE_PORT="5050"
GIT_REPO="https://github.com/J4F3ET/EconomicApp.git"
BRANCH="main"
SERVICE_NAME="economicapp"

# Colores para logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==================== FUNCIONES DE LOG ====================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ==================== VERIFICAR ROOT ====================
if [[ $EUID -ne 0 ]]; then
    log_error "Este script debe ejecutarse como root"
    exit 1
fi

# ==================== MENÚ DE INSTALACIÓN ====================
show_menu() {
    echo ""
    echo "╔════════════════════════════════════════════════════╗"
    echo "║     EconomicApp - Script de Despliegue           ║"
    echo "╠════════════════════════════════════════════════════╣"
    echo "║  1. Instalar dependencias completas              ║"
    echo "║  2. Desplegar con Docker                         ║"
    echo "║  3. Desplegar directo (.NET SDK)                ║"
    echo "║  4. Solo actualizar desde Git                   ║"
    echo "║  5. Verificar estado del servicio              ║"
    echo "║  6. Reiniciar servicio                         ║"
    echo "║  7. Ver logs                                    ║"
    echo "║  8. Salir                                       ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    read -p "Seleccione una opción: " option
}

# ==================== INSTALAR DEPENDENCIAS ====================
install_dependencies() {
    log_info "Instalando dependencias..."
    
    # Actualizar sistema
    apt update && apt upgrade -y
    
    # Instalar dependencias básicas
    apt install -y curl wget git ufw fail2ban
    
    # Instalar .NET 8 SDK
    log_info "Instalando .NET 8 SDK..."
    wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    apt update
    
    # Instalar SDK (no runtime, para build)
    apt install -y aspnetcore-sdk-8.0
    
    # Instalar Docker si se selecciona
    log_info "Instalando Docker..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
    rm /tmp/get-docker.sh
    
    # Habilitar Docker
    systemctl enable docker
    systemctl start docker
    
    log_success "Dependencias instaladas correctamente"
}

# ==================== CREAR ARCHIVOS DE DOCKER ====================
create_docker_files() {
    log_info "Creando archivos Docker..."
    
    # Dockerfile
    cat > /opt/${APP_NAME}/Dockerfile << 'EOF'
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copiar archivos del proyecto
COPY . .
RUN dotnet restore EconomicApp.csproj
RUN dotnet publish EconomicApp.csproj -c Release -o /app/publish

# Imagen de producción
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

# Configuración de puerto y producción
ENV ASPNETCORE_URLS=http://+:5050
ENV ASPNETCORE_ENVIRONMENT=Production
EXPOSE 5050

ENTRYPOINT ["dotnet", "EconomicApp.dll"]
EOF

    # Docker Compose
    cat > /opt/${APP_NAME}/docker-compose.yml << 'EOF'
version: '3.8'

services:
  economicapp:
    build: .
    container_name: economicapp
    restart: unless-stopped
    ports:
      - "5050:5050"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5050"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - economicapp-network

networks:
  economicapp-network:
    driver: bridge
EOF

    log_success "Archivos Docker creados"
}

# ==================== CLONAR/ACTUALIZAR REPO ====================
deploy_from_git() {
    log_info "Desplegando desde Git..."
    
    APP_DIR="/opt/${APP_NAME}"
    
    # Crear directorio si no existe
    mkdir -p ${APP_DIR}
    
    # Si es un clon existente, hacer pull
    if [ -d "${APP_DIR}/.git" ]; then
        log_info "Repositorio existente, actualizando..."
        cd ${APP_DIR}
        git stash
        git checkout ${BRANCH}
        git pull origin ${BRANCH}
    else
        log_info "Clonando repositorio..."
        git clone -b ${BRANCH} ${GIT_REPO} ${APP_DIR}
    fi
    
    log_success "Código actualizado desde Git"
}

# ==================== DESPLIEGUE CON DOCKER ====================
deploy_docker() {
    deploy_from_git
    create_docker_files
    
    APP_DIR="/opt/${APP_NAME}"
    cd ${APP_DIR}
    
    log_info "Construyendo imagen Docker..."
    docker build -t economicapp:latest .
    
    log_info "Iniciando contenedor..."
    docker-compose up -d
    
    log_success "Aplicación desplegada con Docker"
    log_info "Acceso: http://localhost:${APP_PORT}"
}

# ==================== DESPLIEGUE DIRECTO ====================
deploy_direct() {
    deploy_from_git
    
    APP_DIR="/opt/${APP_NAME}"
    BUILD_DIR="${APP_DIR}/bin/publish"
    
    log_info "Compilando aplicación..."
    cd ${APP_DIR}
    dotnet publish -c Release -o ${BUILD_DIR} --self-contained false
    
    log_info "Creando servicio systemd..."
    
    cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=EconomicApp - Simulador de Créditos
After=network.target

[Service]
WorkingDirectory=${BUILD_DIR}
ExecStart=/usr/bin/dotnet ${BUILD_DIR}/EconomicApp.dll
Restart=always
RestartSec=10
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://localhost:${APP_PORT}

[Install]
WantedBy=multi-user.target
EOF

    # Habilitar yiciar servicio
    systemctl daemon-reload
    systemctl enable ${SERVICE_NAME}
    systemctl restart ${SERVICE_NAME}
    
    log_success "Aplicación desplegada directamente"
    log_info "Servicio: systemctl status ${SERVICE_NAME}"
}

# ==================== VERIFICAR ESTADO ====================
check_status() {
    log_info "Verificando estado del servicio..."
    
    if systemctl is-active --quiet ${SERVICE_NAME}; then
        log_success "El servicio está activo y corriendo"
        
        # Verificar puerto
        if ss -tlnp | grep -q ":${APP_PORT}"; then
            log_success "El puerto ${APP_PORT} está escuchando"
        else
            log_warning "El puerto ${APP_PORT} no está escuchando"
        fi
        
        # Verificar proceso
        log_info "Procesos dotnet corriendo:"
        ps aux | grep dotnet | grep -v grep
    else
        log_error "El servicio no está corriendo"
        log_info "Últimos logs:"
        journalctl -u ${SERVICE_NAME} -n 20 --no-pager
    fi
}

# ==================== VER LOGS ====================
view_logs() {
    log_info "Últimos 50 logs del servicio..."
    journalctl -u ${SERVICE_NAME} -n 50 --no-pager -f
}

# ==================== CONFIGURAR TAILSCALE ====================
setup_tailscale() {
    log_info "Configurando Tailscale..."
    
    # Instalar Tailscale
    curl -fsSL https://tailscale.com/install.sh | sh
    
    # Iniciar sesión (requiere autenticación manual)
    log_warning "Necesitas autenticarte con: tailscale up --operator=root"
    log_info "Después de autenticar, la app estará accesible via Tailscale"
}

# ==================== SCRIPT PRINCIPAL ====================
main() {
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║   EconomicApp Deployment Script                     ║"
    echo "║   Entorno: LXC + Tailscale + .NET 8                ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    
    while true; do
        show_menu
        
        case $option in
            1)
                install_dependencies
                read -p "Presione Enter para continuar..."
                ;;
            2)
                deploy_docker
                read -p "Presione Enter para continuar..."
                ;;
            3)
                deploy_direct
                read -p "Presione Enter para continuar..."
                ;;
            4)
                deploy_from_git
                read -p "Presione Enter para continuar..."
                ;;
            5)
                check_status
                read -p "Presione Enter para continuar..."
                ;;
            6)
                log_info "Reiniciando servicio..."
                systemctl restart ${SERVICE_NAME}
                log_success "Servicio reiniciado"
                read -p "Presione Enter para continuar..."
                ;;
            7)
                view_logs
                ;;
            8)
                log_info "¡Hasta luego!"
                exit 0
                ;;
            *)
                log_error "Opción no válida"
                ;;
        esac
    done
}

# Ejecutar
main