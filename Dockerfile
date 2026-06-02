# EconomicApp Dockerfile
# Multi-stage build for optimized production image

# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copiar solo archivos necesarios para restore
COPY EconomicApp.csproj ./
RUN dotnet restore EconomicApp.csproj

# Copiar todo el código y compilar
COPY . .
RUN dotnet publish EconomicApp.csproj -c Release -o /app/publish --no-restore

# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Crear usuario no-root para seguridad
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

# Copiar archivos compilados
COPY --from=build /app/publish .

# Variables de entorno
ENV ASPNETCORE_URLS=http://+:5050
ENV ASPNETCORE_ENVIRONMENT=Production
ENV DOTNET_RUNNING_IN_CONTAINER=true

# Exponer puerto
EXPOSE 5050

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5050/ || exit 1

# Startup
ENTRYPOINT ["dotnet", "EconomicApp.dll"]