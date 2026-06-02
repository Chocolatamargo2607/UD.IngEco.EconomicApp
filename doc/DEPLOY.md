# 🚀 Guía de Despliegue de EconomicApp

Esta guía explica cómo utilizar los scripts automatizados proporcionados para desplegar la aplicación en entornos Linux (optimizados para contenedores **LXC** y redes **Tailscale**).

La aplicación está construida en **.NET 8** y expone el puerto **5050** por defecto.

---

## 🛠️ Opción 1: Despliegue Interactivo (Recomendado para principiantes)

**Archivo:** `scripts/deploy.sh`

Este script proporciona un menú interactivo en la terminal que te guía paso a paso. Es ideal si prefieres tener control visual de lo que estás instalando.

**Instrucciones:**

1. Da permisos de ejecución al script:
```bash
chmod +x scripts/deploy.sh

```


2. Ejecútalo como administrador (`root`):
```bash
sudo ./scripts/deploy.sh

```



**Opciones del Menú:**

* **1) Instalar dependencias:** Prepara el servidor instalando `curl`, `git`, y el SDK de `.NET 8`.
* **2) Desplegar con Docker:** Usa el `Dockerfile` y `docker-compose.yml` para levantar la app aislada en un contenedor.
* **3) Desplegar directo (.NET):** Compila la app y la instala nativamente como un servicio de `systemd` en Linux.
* **4) Solo actualizar (Git):** Hace `git pull` de los últimos cambios y recompila la aplicación.
* **5-7) Gestión del servicio:** Permite ver el estado (`status`), reiniciar la app, y ver los registros (`logs`) en tiempo real.

---

## ⚡ Opción 2: Despliegue Rápido por Consola (Ideal para CI/CD)

**Archivo:** `scripts/deploy-simple.sh`

Diseñado para instalaciones de un solo comando o flujos automatizados. Acepta parámetros directamente desde la línea de comandos.

**Instrucción de despliegue rápido vía web (Curl):**

```bash
curl -fsSL https://raw.githubusercontent.com/TU_USUARIO/EconomicApp/main/scripts/deploy-simple.sh | sudo bash -s -- --repo https://github.com/TU_USUARIO/EconomicApp.git --branch main

```

**Uso local con parámetros:**

```bash
chmod +x scripts/deploy-simple.sh
sudo ./scripts/deploy-simple.sh [OPCIONES]

```

**Parámetros Disponibles:**

* `--repo URL`: Especifica la URL del repositorio Git.
* `--branch NOMBRE`: Especifica la rama a desplegar (Por defecto es `main`).
* `--update`: Solo descarga cambios recientes y recompila (no reinstala todo).
* `--docker`: Fuerza el despliegue usando contenedores Docker.
* `--status`: Muestra el estado del daemon en `systemd`.
* `--logs`: Imprime las últimas 100 líneas del log de la app.
* `--uninstall`: Borra completamente la app, el código y el servicio del servidor.

---

## 🌐 Opción 3: Despliegue Hardcodeado (LXC + Tailscale)

**Archivo:** `scripts/lxc-deploy.sh`

Este script está pensado para ejecutarlo directamente dentro de un contenedor LXC que ya pertenece a una red privada virtual de **Tailscale**.

**Instrucciones:**

1. Abre el archivo y edita la cabecera con los datos exactos de tu repositorio:
```bash
nano scripts/lxc-deploy.sh

```


*Edita estas líneas:*
```bash
GIT_REPO="https://github.com/TU_USUARIO/EconomicApp.git"
BRANCH="main"
PORT=5050

```


2. Ejecuta el script:
```bash
chmod +x scripts/lxc-deploy.sh
sudo ./scripts/lxc-deploy.sh

```



**¿Qué hace al finalizar?**
El script te devolverá por pantalla tanto la URL de `localhost` como la **IP de Tailscale** para que puedas acceder inmediatamente a la aplicación desde cualquier dispositivo de tu VPN privada.

---

## 🐳 Detalles del Despliegue con Docker

Si optas por el despliegue contenerizado (Opción 2 en `deploy.sh` o el flag `--docker`), el sistema utilizará los archivos adjuntos:

* **Dockerfile**: Construcción multi-etapa (Multi-stage build). Usa la imagen `mcr.microsoft.com/dotnet/sdk:8.0` para compilar y luego mueve solo los binarios a una imagen ligera `aspnet:8.0`.
* **Seguridad**: El contenedor ejecuta la aplicación usando un usuario sin privilegios (`appuser`) y no como root.
* **Docker Compose**: Mapea el puerto local `5050` hacia el `5050` del contenedor. Inyecta la variable de entorno `ASPNETCORE_ENVIRONMENT=Production` y mantiene un volumen local llamado `app-logs` para la persistencia de datos y registros.

Para revisar la salud del contenedor en Docker, `docker-compose.yml` ya incluye un `healthcheck` que hace `curl` a la app cada 30 segundos.