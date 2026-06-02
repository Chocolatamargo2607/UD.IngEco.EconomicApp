# 📈 EconomicApp - Simulador de Créditos Académico

## 📖 Descripción del Proyecto
**EconomicApp** es un simulador de créditos simplificado diseñado específicamente para la asignatura de Ingeniería Económica. Su objetivo principal es proporcionar una herramienta educativa que permita a los estudiantes modelar préstamos, convertir tasas, calcular capitalizaciones y exportar reportes de amortización. 

A diferencia de los simuladores comerciales tradicionales ("cajas negras"), este software adopta un enfoque pedagógico, permitiendo al usuario interactuar con los parámetros financieros fundamentales para comprender el comportamiento del dinero en el tiempo.

## ✨ Funcionalidades Principales
* **Configuración de Créditos:** Ingreso dinámico de capital, plazos y periodicidad de pagos.
* **Gestión y Conversión de Tasas:** Entrada de tasas Nominales y Efectivas con conversión automática a la tasa efectiva periódica equivalente[cite: 4, 5].
* **Sistemas de Amortización:** Comparación directa entre el Sistema Francés (Cuota Fija) y el Sistema Alemán (Abono Constante).
* **Escenarios Complejos:** Simulación de frecuencias de capitalización y periodos de gracia muertos.
* **Reportes Exportables:** Generación de tablas dinámicas detalladas (cuota, interés, abono a capital y saldo) con opciones de exportación a PDF o Excel/CSV.

## 🛠️ Stack Tecnológico
* **Frontend / UI:** Blazor (WebAssembly/Server) con HTML, CSS y Bootstrap.
* **Backend / Lógica:** C# (.NET).
* **Arquitectura:** Componentes Razor modulares.

## 🚀 Historias de Usuario Principales
* **HU-01:** Parametrización del Préstamo.
* **HU-02:** Equivalencia de Tasas.
* **HU-03:** Visualización de la Tabla de Pagos.
* **HU-04:** Comparativa Francés vs. Alemán.
* **HU-05:** Escenarios de Capitalización.
* **HU-06:** Descarga de Reporte de Amortización.
```mermaid
graph TD
    %% Definición de Estilos
    classDef UI fill:#0078D7,stroke:#005A9E,stroke-width:2px,color:white;
    classDef Logic fill:#28A745,stroke:#1E7E34,stroke-width:2px,color:white;
    classDef Error fill:#DC3545,stroke:#C82333,stroke-width:2px,color:white;
    classDef State fill:#FFC107,stroke:#D39E00,stroke-width:2px,color:black;

    %% Nodos
    A[Inicio: Usuario accede a la vista de Simulación]:::UI --> B(Formulario: Ingreso de Parámetros RF-01):::UI
    
    B --> C{Ingresa Monto / Capital}
    C --> |Monto <= 0| E[Mostrar Error: El monto debe ser mayor a 0]:::Error
    C --> |Monto > 0| D{Ingresa Plazo / Periodos}
    
    D --> |Plazo <= 0| F[Mostrar Error: El plazo debe ser mayor a 0]:::Error
    D --> |Plazo > 0| G{Selecciona Periodicidad}
    
    E --> B
    F --> B
    
    G --> |Mensual, Trimestral, Semestral, Anual| H[Botón: Validar y Continuar]:::UI
    
    H --> I(Lógica C#: Instanciar Objeto 'ParametrosCredito'):::Logic
    I --> J[Guardar en Estado/Memoria de la App]:::State
    
    J --> K[Habilitar Siguiente Módulo: Ingreso de Tasas RF-02]:::Logic
```