## 📋 Plan de Desarrollo: EconomicApp - Simulador de Créditos

### 🔍 Estado Actual vs Requerido

| Aspecto | Estado Actual | Requerido |
|--------|---------------|-----------|
| **Stack** | ✅ .NET 8 + Blazor Server | Coincide |
| **Estilos** | ✅ Dark theme, Bootstrap 5.3 | Reutilizables |
| **Arquitectura** | ❌ Sin servicios, lógica inline en `@code` | Necesita DTOs + Servicios + API |
| **Simulador Créditos** | ❌ No existe | **PRIORIDAD** |
| **Páginas Relacionadas** | ❌ Interés Simple/Compuesto no existen | Según NavMenu |

---

### 🏗️ FASE 1: Infraestructura Arquitectónica (Backend)

| # | Tarea | Descripción |
|---|-------|-------------|
| 1.1 | Crear carpeta `Models/DTOs/` | DTOs: `SimulacionRequestDto`, `AmortizacionRequestDto`, `CuotaDto`, `ConversionTasaResponseDto`, `AmortizacionResponseDto` |
| 1.2 | Crear carpeta `Services/` | `ITasaService` + `ServicioConversorTasas`, `IAmortizacionService` + `ServicioAmortizacion`, `IReporteService` + `ServicioReportes` |
| 1.3 | Crear `Controllers/Api/SimuladorController.cs` | Endpoints: `/api/simulador/convertir-tasa`, `/api/simulador/generar-tabla`, `/api/simulador/exportar-reporte` |
| 1.4 | Crear `Services/SimuladorApiClient.cs` | Cliente HTTP para el frontend |

---

### 🖥️ FASE 2: Interfaz del Simulador (Frontend)

| # | Tarea | Descripción |
|---|-------|-------------|
| 2.1 | Crear `Pages/Simulador.razor` | Formulario principal con las 3 tarjetas Bootstrap |
| 2.2 | Tarjeta 1: Datos del Préstamo | Monto(P), Plazo(n), Frecuencia de pago |
| 2.3 | Tarjeta 2: Perfil de Tasa | Valor, Tipo (Nominal/Efectiva), Frecuencia |
| 2.4 | Tarjeta 3: Amortización | Sistema (Francés/Alemán), Periodos de gracia |
| 2.5 | Renderizar Tabla de Amortización | Con `@if` condicional + `@foreach` |
| 2.6 | Comparativa Instantánea | `@onchange` en radio buttons |
| 2.7 | Botones Exportar | PDF + Excel con `IJSRuntime` |

---

### 🔢 FASE 3: Lógica Matemática

| # | Servicio | Implementar |
|---|----------|-------------|
| 3.1 | `ServicioConversorTasas` | Conversión Nominal→Efectiva, Equivalencia de tasas |
| 3.2 | `ServicioAmortizacion` | Sistema Francés (cuota fija), Sistema Alemán (abono constante), Periodos de gracia con capitalización |
| 3.3 | `ServicioReportes` | Generación PDF (QuestPDF/iText7) y Excel (ClosedXML/EPPlus) |

---

### ⚡ Detalles Técnicos Importantes

- **Precisión:** 6 decimales internos mínimo para evitar errores de redondeo
- **Saldo final:** Debe tender a $0.00$ exactamente
- **Enfoque pedagógico:** Mostrar tasas convertidas antes de calcular
- **Reutilizar estilos:** Mantener el tema oscuro con `css/app.css` existente

---

### 📁 Estructura Objetivo

```
EconomicApp/
├── Models/DTOs/
│   ├── SimulacionRequestDto.cs
│   ├── AmortizacionRequestDto.cs
│   ├── ConversionTasaResponseDto.cs
│   ├── CuotaDto.cs
│   └── AmortizacionResponseDto.cs
├── Services/
│   ├── ITasaService.cs
│   ├── ServicioConversorTasas.cs
│   ├── IAmortizacionService.cs
│   ├── ServicioAmortizacion.cs
│   ├── IReporteService.cs
│   └── ServicioReportes.cs
├── Controllers/Api/
│   └── SimuladorController.cs
├── Pages/
│   └── Simulador.razor
└── Services/
    └── SimuladorApiClient.cs (Frontend)
```

### 📅 Cronograma Tentativo
| Semana | Tareas Principales |
|--------|-------------------|
| 1-2 | Fase 1: Infraestructura Backend |
| 3-4 | Fase 2: Interfaz del Simulador |
| 5-6 | Fase 3: Lógica Matemática |
| 7-8 | Detalles Técnicos, Pruebas y Ajustes Finales |

---
