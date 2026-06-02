# Documento de Diseño Arquitectónico y Técnico: Simulador de Créditos

**Stack Objetivo:** .NET, Blazor (WebAssembly/Server), Bootstrap.

**Patrón Arquitectónico:** Cliente-Servidor (Stateless / Sin base de datos).

**Regla de Diseño:** Teoría Matemática $\rightarrow$ Variables Identificadas $\rightarrow$ Campos del Formulario (UI) $\rightarrow$ DTOs y Endpoints.

---

## 1. Modelado Matemático y Diseño de Interfaz (UI)

Esta sección define las fórmulas que rigen el motor y cómo se mapean visualmente en el formulario construido con Bootstrap.

### 1.1. Parametrización y Tasas (HU-01 y HU-02)

Antes de calcular cualquier cuota, el dinero ($P$) y el tiempo ($n$) deben estar en la misma unidad de medida que la tasa de interés ($i$).

* **Conversión de Tasa Nominal a Efectiva:** $i = \frac{r}{m}$
* **Equivalencia de Tasas Efectivas:** $i_2 = (1 + i_1)^{\frac{n_1}{n_2}} - 1$

### 1.2. Sistemas de Amortización y Capitalización (HU-03, HU-04, HU-05)

* **Sistema Francés (Cuota Fija):** $A = P \left[ \frac{i(1+i)^n}{(1+i)^n - 1} \right]$
* **Sistema Alemán (Abono Constante):** $C = \frac{P}{n}$
* **Periodo de Gracia (Capitalización):** $P_{nuevo} = P \times (1+i)^g$ (donde $g$ son los periodos de gracia).

### 1.3. Estructura de la Vista Principal (Tarjetas Bootstrap)

El formulario de captura en Blazor se dividirá en 3 tarjetas (`cards`):

* **Tarjeta 1: Datos del Préstamo**
* `col-md-6`: Input Numérico $\rightarrow$ Monto del Préstamo ($P$)
* `col-md-3`: Input Numérico $\rightarrow$ Plazo total en periodos ($n$)
* `col-md-3`: Select $\rightarrow$ Periodicidad del Plazo (Mensual, Trimestral, Anual, etc.)


* **Tarjeta 2: Perfil de la Tasa de Interés**
* `col-md-4`: Input Numérico $\rightarrow$ Valor de la Tasa (%)
* `col-md-4`: Select $\rightarrow$ Tipo de Tasa (Nominal, Efectiva)
* `col-md-4`: Select $\rightarrow$ Periodicidad de la Tasa (Anual, Mensual, etc.)


* **Tarjeta 3: Configuración de la Amortización**
* `col-md-6`: Radio Buttons $\rightarrow$ Sistema (Cuota Fija - Francés / Abono Constante - Alemán)
* `col-md-6`: Input Numérico $\rightarrow$ Periodos de Gracia ($g$) *(Por defecto: 0)*
* `row mt-4`: Botón de Acción primario $\rightarrow$ **"Simular Crédito"**



---

## 2. Arquitectura del Backend (.NET Web API)

El backend actuará exclusivamente como el "Motor Matemático" (Stateless). Recibe los datos, calcula y devuelve las respuestas.

### 2.1. Clases de Transferencia de Datos (DTOs)

Las clases con las que el Front y el Back se comunican:

* **Entradas (Requests):**
* `SimulacionRequestDto`: Contiene Monto, Plazo, FrecuenciaPago, ValorTasa, TipoTasa, FrecuenciaTasa.
* `AmortizacionRequestDto`: Contiene Capital, Plazo, TasaEfectivaPeriodica, SistemaAmortizacion y PeriodosGracia.
* `ExportarReporteRequestDto`: Hereda de `AmortizacionRequestDto` y añade `FormatoExportacion` (Enum: PDF, Excel).


* **Salidas (Responses):**
* `ConversionTasaResponseDto`: Retorna `TasaEfectivaPeriodica` (decimal), `EsExitoso` (bool) y `Mensaje` (string).
* `CuotaDto` (Fila de tabla): `NumeroPeriodo`, `SaldoInicial`, `Interes`, `AbonoCapital`, `ValorCuota`, `SaldoFinal`.
* `AmortizacionResponseDto`: Retorna `TablaAmortizacion` (List), `TotalInteresesPagados` y `TotalPagado`.



### 2.2. Capa de Servicios (Lógica de Negocio)

* `ServicioConversorTasas`: Lee el `TipoTasa` del request y aplica la división simple (Nominal) o la equivalencia fraccionaria (Efectiva).
* `ServicioAmortizacion`:
* **Fase 1 (Gracia):** Si `PeriodosGracia > 0`, itera sumando los intereses al saldo final (Capitalización) con cuotas en $0$.
* **Fase 2 (Amortización):** Usa el `SaldoFinal` capitalizado como nuevo monto y aplica un `switch` para usar las fórmulas del Sistema Francés o Alemán, garantizando que en el periodo final ($n$) el saldo sea $0.00$.


* `ServicioReportes`: Llama a `ServicioAmortizacion` en memoria, da formato a los resultados usando librerías (ej. iText7 o EPPlus) y retorna un `byte[]`.

### 2.3. Endpoints (Controladores API)

* `POST /api/simulador/convertir-tasa` $\rightarrow$ Recibe `SimulacionRequestDto`, retorna `ConversionTasaResponseDto` (JSON).
* `POST /api/simulador/generar-tabla` $\rightarrow$ Recibe `AmortizacionRequestDto`, retorna `AmortizacionResponseDto` (JSON).
* `POST /api/simulador/exportar-reporte` $\rightarrow$ Recibe `ExportarReporteRequestDto`, retorna un `FileResult` (binario de Excel o PDF).

---

## 3. Arquitectura del Frontend (Blazor WebAssembly / Server)

El código de la vista (HTML/Bootstrap) delega toda la lógica matemática pesada al backend.

### 3.1. Cliente HTTP (`SimuladorApiClient`)

Servicio inyectado en los componentes `.razor` que gestiona las peticiones HTTP mediante `HttpClient`:

* `ObtenerTasaConvertidaAsync(...)`
* `ObtenerTablaAmortizacionAsync(...)`
* `DescargarReporteAsync(...)`

### 3.2. Estado y Renderizado del Componente

* **Gestión de Estado:** El formulario utiliza la directiva `@bind-Value` para enlazar los inputs de Bootstrap directamente a una instancia local del DTO.
* **Ciclo de Simulación:** El botón "Simular Crédito" llama primero a `ObtenerTasaConvertidaAsync`. Una vez obtenida la tasa periódica exitosamente, llama inmediatamente a `ObtenerTablaAmortizacionAsync` y guarda el resultado en una variable de estado.
* **Renderizado de la Tabla:** Usando una directiva `@if (resultadoAmortizacion != null)`, se dibuja una tabla (`<table class="table table-striped">`). Un bucle `@foreach` recorre la lista de cuotas creando las filas `<tr>`. Se incluye un panel lateral/superior para mostrar los totales (Costo del crédito).

### 3.3. Interactividad Avanzada

* **Comparativa Instantánea (HU-04):** Los Radio Buttons del sistema de amortización tienen un evento `@onchange`. Al alternar entre Francés y Alemán, se dispara la regeneración de la tabla de forma asíncrona sin recargar la página.
* **Descarga de Reportes (HU-06):** Se incluyen dos botones (PDF y Excel). Al hacer clic, consumen el endpoint binario y utilizan **JS Interop** (`IJSRuntime`) para forzar la descarga del archivo en el navegador web del usuario.


// --- FIN DEL DOCUMENTO --- //

# Esquema Teórico y de Interfaz: Simulador de Créditos

**Stack Objetivo:** .NET, Blazor (WebAssembly/Server), Bootstrap.
**Regla de Diseño:** Teoría Matemática $\rightarrow$ Variables Identificadas $\rightarrow$ Campos del Formulario (UI).

---

## 1. Historias de Usuario 01 y 02: Parametrización y Equivalencia de Tasas

### A. Teoría Matemática (Fórmulas)
Antes de calcular cualquier cuota, necesitamos llevar el dinero ($P$) y el tiempo ($n$) a la misma unidad de medida que la tasa de interés ($i$).

1.  **Conversión de Tasa Nominal a Efectiva Periódica:**
    Si el usuario ingresa una tasa Nominal, se divide por su frecuencia de capitalización.
    $$i = \frac{r}{m}$$
    *(Donde $r$ es la tasa nominal y $m$ el número de periodos de capitalización en el año).*

2.  **Equivalencia de Tasas Efectivas:**
    Si el usuario ingresa una tasa Efectiva Anual (EA) y los pagos son mensuales, hay que hallar la tasa periódica equivalente.
    $$(1 + i_1)^{n_1} = (1 + i_2)^{n_2} \Rightarrow i_2 = (1 + i_1)^{\frac{n_1}{n_2}} - 1$$
    *(Donde $i_1$ es la tasa conocida, e $i_2$ es la tasa periódica buscada).*

### B. Variables Extraídas de la Teoría
Para que el backend (C#) pueda resolver esas fórmulas, necesita conocer obligatoriamente:
* $P$: Monto del crédito (Capital).
* $n$: Plazo total o número de cuotas.
* Frecuencia de pago: Para saber en qué unidades está $n$ (Meses, Trimestres, etc.).
* $r$ o $i_1$: Valor numérico de la tasa ingresada.
* Tipo de Tasa: ¿Es Nominal o Efectiva?
* Frecuencia de la Tasa: ¿Es Anual, Mensual, Semestral?

### C. Esquema del Formulario (Bootstrap UI para Blazor)
Basado en las variables, el formulario se dividirá en dos tarjetas (`card` de Bootstrap):

**Tarjeta 1: Datos del Préstamo**
* **Fila 1 (`row`):**
    * `col-md-6`: Input Numérico $\rightarrow$ **Monto del Préstamo ($P$)**
    * `col-md-3`: Input Numérico $\rightarrow$ **Plazo ($n$)**
    * `col-md-3`: Select (Dropdown) $\rightarrow$ **Periodicidad del Plazo** *(Mensual, Bimestral, Trimestral, Semestral, Anual)*

**Tarjeta 2: Perfil de la Tasa de Interés**
* **Fila 2 (`row`):**
    * `col-md-4`: Input Numérico $\rightarrow$ **Valor de la Tasa (%)**
    * `col-md-4`: Select (Dropdown) $\rightarrow$ **Tipo de Tasa** *(Nominal, Efectiva)*
    * `col-md-4`: Select (Dropdown) $\rightarrow$ **Periodicidad de la Tasa** *(Anual, Mensual, etc.)*

*(Nota Blazor: Estos campos se mapearán directamente mediante `@bind-Value` a las propiedades de tu modelo en C#).*
# Diseño Arquitectónico: Parametrización y Conversión de Tasas (HU-01 y HU-02)

## 1. Definición de Roles

### Frontend (Blazor + Bootstrap)
* **Responsabilidad:** Renderizar la interfaz de usuario (las tarjetas que diseñamos), capturar la entrada del usuario y realizar validaciones de formato básicas (ej. que no metan letras en campos numéricos, o valores negativos).
* **Interacción:** Recopilará los datos de los inputs, los empaquetará en un objeto y se los enviará al Backend a través de una petición HTTP. Al recibir la respuesta, actualizará la vista.

### Backend (.NET Web API)
* **Responsabilidad:** Actuar como el "Motor Matemático". Recibirá los parámetros, ejecutará las reglas de negocio (fórmulas de conversión de tasas) y devolverá el resultado exacto.
* **Interacción:** Expondrá rutas (endpoints) a las que el Frontend puede "llamar" para pedir cálculos.

---

## 2. Diseño del Backend (.NET)

Al no tener base de datos, no necesitamos "Entidades" de Entity Framework. Usaremos **DTOs** (Data Transfer Objects), que son clases simples para transportar datos entre el Front y el Back.

### A. Clases de Modelo (DTOs)
Necesitamos definir cómo viaja la información:

1.  **`SimulacionRequestDto`:** (Lo que envía el Front al Back)
    * `MontoPrestamo` (decimal)
    * `Plazo` (int)
    * `FrecuenciaPago` (Enum: Mensual, Trimestral, Semestral, Anual)
    * `ValorTasa` (decimal)
    * `TipoTasa` (Enum: Nominal, Efectiva)
    * `FrecuenciaTasa` (Enum: Mensual, Anual, etc.)

2.  **`ConversionTasaResponseDto`:** (Lo que el Back le responde al Front para la HU-02)
    * `TasaEfectivaPeriodica` (decimal) - *El resultado matemático final.*
    * `EsExitoso` (boolean) - *Para saber si el cálculo se pudo hacer.*
    * `Mensaje` (string) - *Ej: "Tasa convertida exitosamente de Nominal Anual a Efectiva Mensual".*

### B. Capa de Servicios (Lógica de Negocio)
Aquí es donde viven las fórmulas matemáticas que vimos en la teoría.

1.  **`ServicioConversorTasas` (o `ITasaService`):**
    * **Método principal:** `CalcularTasaPeriodica(SimulacionRequestDto request)`
    * **Lógica interna:** Este servicio leerá el `TipoTasa`. 
        * Si es *Nominal*, aplicará la fórmula de división simple por la frecuencia.
        * Si es *Efectiva*, aplicará la fórmula de equivalencia con exponentes fraccionarios para igualarla a la `FrecuenciaPago`.

### C. Endpoints (Controladores API)
El "puerto de escucha" del backend.

* **Ruta:** `POST /api/simulador/convertir-tasa`
* **Acción:** Recibe en el cuerpo (Body) de la petición un JSON equivalente al `SimulacionRequestDto`, se lo pasa al `ServicioConversorTasas`, y devuelve un HTTP 200 (OK) con el `ConversionTasaResponseDto`.

---

## 3. Diseño del Frontend (Blazor)

En Blazor, el código de la vista (HTML/Bootstrap) necesita un intermediario para hablar con el Backend.

### A. Servicios de Integración (API Client)
1.  **`SimuladorApiClient` (o `ISimuladorService`):**
    * Es una clase en el proyecto de Blazor que inyecta un `HttpClient`.
    * **Método principal:** `ObtenerTasaConvertidaAsync(SimulacionRequestDto datosFormulario)`
    * **Lógica:** Toma el objeto del formulario, lo serializa a JSON, hace un POST al endpoint `/api/simulador/convertir-tasa` y deserializa la respuesta para que la vista la pueda usar.

### B. Estado de la Vista (Componente de Blazor)
El archivo `.razor` tendrá asociado un modelo en memoria:
* Una instancia de `SimulacionRequestDto` enlazada directamente a los inputs de Bootstrap mediante `@bind-Value`.
* Un evento en el botón "Calcular" (ej. `OnValidSubmit`) que invoca al `SimuladorApiClient`.
* Una variable para almacenar la `TasaEfectivaPeriodica` que devuelve el servidor y mostrarla en pantalla con un mensaje de éxito.
---

## 2. Historias de Usuario 03 y 04: Sistemas de Amortización

### A. Teoría Matemática (Fórmulas)
Una vez que el backend calculó la Tasa Efectiva Periódica ($i$) que coincide con los pagos, aplicamos los sistemas de amortización:

1.  **Sistema Francés (Cuota Fija):**
    La cuota es constante. Se calcula con la fórmula de anualidad vencida:
    $$A = P \left[ \frac{i(1+i)^n}{(1+i)^n - 1} \right]$$
    * *Interés del periodo:* $I_t = Saldo_{t-1} \times i$
    * *Abono a capital:* $C_t = A - I_t$

2.  **Sistema Alemán (Abono Constante a Capital):**
    El abono a capital es constante, la cuota total disminuye.
    $$C = \frac{P}{n}$$
    * *Interés del periodo:* $I_t = Saldo_{t-1} \times i$
    * *Cuota del periodo:* $A_t = C + I_t$

### B. Variables Extraídas de la Teoría
Ya tenemos $P$, $n$, e $i$ del paso anterior. Solo nos falta que el usuario le diga al motor matemático qué juego de fórmulas utilizar (Francés o Alemán).

### C. Esquema del Formulario (Bootstrap UI para Blazor)
Agregamos una tercera tarjeta al formulario.

**Tarjeta 3: Configuración de la Amortización**
* **Fila 3 (`row`):**
    * `col-md-12`: Radio Buttons (o Select) $\rightarrow$ **Sistema de Amortización** *(Opciones: Cuota Fija - Francés / Abono Constante - Alemán)*.

* **Fila 4 (`row mt-4`):**
    * `col-md-12 text-center`: Botón de Acción (`btn btn-primary`) $\rightarrow$ **"Simular Crédito"** *(Este botón disparará el evento OnValidSubmit en Blazor para ejecutar las matemáticas y renderizar la tabla).*

---
# Diseño Arquitectónico: Sistemas de Amortización (HU-03 y HU-04)

## 1. Definición de Roles

### Frontend (Blazor + Bootstrap)
* **Responsabilidad:** Tomar los datos previamente validados (Capital, Plazo, Tasa Periódica) más el sistema de amortización seleccionado por el usuario (Radio Buttons) y enviarlos al backend. Una vez reciba la respuesta, renderizará los datos iterando sobre una grilla tipo `<table class="table table-striped">` de Bootstrap.
* **Interacción (Comparativa):** Al cambiar la selección entre "Francés" y "Alemán", el frontend hará una nueva petición silenciosa al backend y redibujará la tabla al instante, brindando una experiencia fluida sin recargar la página.

### Backend (.NET Web API)
* **Responsabilidad:** Actuar como el "Motor Generador". Recibe las condiciones del crédito, identifica si debe usar las fórmulas del Sistema Francés (anualidad vencida) o Alemán (abono constante), e itera periodo por periodo ($1$ hasta $n$) calculando los saldos.
* **Reto Matemático:** El backend debe asegurar precisión decimal. En el último periodo ($n$), el `SaldoFinal` debe tender exactamente a $0.00$.

---

## 2. Diseño del Backend (.NET)

Para que la tabla viaje correctamente por la red, necesitamos definir los objetos de transferencia de datos (DTOs) que representarán las filas y el resumen del crédito.

### A. Clases de Modelo (DTOs)

1. **`AmortizacionRequestDto`:** (Lo que envía el Front al Back)
   * `Capital` (decimal) - *Monto del préstamo.*
   * `Plazo` (int) - *Número de cuotas.*
   * `TasaEfectivaPeriodica` (decimal) - *El resultado que calculamos en la HU-02.*
   * `SistemaAmortizacion` (Enum: Frances, Aleman) - *Para que el motor sepa qué bucle ejecutar.*

2. **`CuotaDto`:** (Representa una sola fila de la tabla)
   * `NumeroPeriodo` (int) - *0, 1, 2, ..., n.*
   * `SaldoInicial` (decimal)
   * `Interes` (decimal)
   * `AbonoCapital` (decimal)
   * `ValorCuota` (decimal)
   * `SaldoFinal` (decimal)

3. **`AmortizacionResponseDto`:** (La respuesta completa del Back al Front)
   * `TablaAmortizacion` (List<CuotaDto>) - *La lista de todas las filas.*
   * `TotalInteresesPagados` (decimal) - *Sumatoria útil para comparar qué sistema es más barato.*
   * `TotalPagado` (decimal) - *Capital + TotalIntereses.*

### B. Capa de Servicios (Lógica de Negocio)

1. **`ServicioAmortizacion` (o `IAmortizacionService`):**
   * **Método principal:** `GenerarTabla(AmortizacionRequestDto request)`
   * **Lógica interna:** Utilizará una estructura condicional (`switch` o `if/else`) basada en el `SistemaAmortizacion`.
     * **Si es Francés:** Calcula primero el valor de la cuota fija (A) con la fórmula general. Luego hace un bucle `for` calculando el interés sobre el saldo anterior y restándolo de la cuota para hallar el abono a capital.
     * **Si es Alemán:** Calcula primero el abono a capital fijo ($C = Capital / Plazo$). Luego hace el bucle calculando el interés sobre el saldo anterior y sumándolo al abono a capital para hallar la cuota variable.
   * Al finalizar el bucle, suma la columna de intereses y llena el `AmortizacionResponseDto`.

### C. Endpoints (Controladores API)

* **Ruta:** `POST /api/simulador/generar-tabla`
* **Acción:** Recibe el `AmortizacionRequestDto`, llama al `ServicioAmortizacion`, y devuelve un HTTP 200 (OK) con el JSON que contiene la lista de cuotas y los totales.

---

## 3. Diseño del Frontend (Blazor)

Aquí es donde la magia se hace visible para el usuario mediante la interactividad de Blazor.

### A. Servicios de Integración (API Client)
1. **`SimuladorApiClient`:**
   * **Nuevo Método:** `ObtenerTablaAmortizacionAsync(AmortizacionRequestDto request)`
   * **Lógica:** Hace el POST al endpoint `/api/simulador/generar-tabla` y guarda la respuesta en una variable del componente.

### B. Estado de la Vista (Componente de Blazor)
* **Variables de Estado:** * Una variable `AmortizacionResponseDto? resultadoAmortizacion` (inicialmente nula).
* **Renderizado Condicional (UI):**
  * Usaremos la directiva `@if (resultadoAmortizacion != null)` en el HTML. Si hay datos, mostramos un bloque con dos tarjetas de Bootstrap:
    * **Tarjeta Izquierda/Superior:** Un pequeño panel de "Resumen" mostrando el `TotalInteresesPagados` (Criterio de aceptación de HU-03).
    * **Tarjeta Principal:** Un bucle `@foreach (var fila in resultadoAmortizacion.TablaAmortizacion)` que dibuja cada fila (`<tr>`) con sus respectivas celdas (`<td>`) dentro de la tabla.
* **Interactividad (HU-04):** * Los *Radio Buttons* para elegir Francés/Alemán tendrán un evento `@onchange`. Cada vez que el usuario cambie la opción, este evento llamará automáticamente al método `ObtenerTablaAmortizacionAsync` y la tabla se actualizará frente a sus ojos en fracciones de segundo.
## 3. Historia de Usuario 05: Periodos de Gracia (Capitalización)

### A. Teoría Matemática (Fórmulas)
Si hay un periodo de gracia "muerto", el cliente no paga nada durante $g$ periodos, pero los intereses se generan y se suman al capital (se capitalizan).
* **Nuevo Capital a Amortizar ($P_{nuevo}$):**
    $$P_{nuevo} = P \times (1+i)^g$$
    *(Donde $g$ es la cantidad de periodos de gracia).*
* Una vez calculado $P_{nuevo}$, este se convierte en el capital inicial para aplicar las fórmulas del Sistema Francés o Alemán.

### B. Variables Extraídas de la Teoría
* $g$: Número de periodos de gracia.

### C. Esquema del Formulario (Bootstrap UI para Blazor)
Actualizamos la Tarjeta 3 para incluir esta variable.

**Tarjeta 3: Configuración de la Amortización (Actualizada)**
* **Fila 3 (`row`):**
    * `col-md-6`: Radio Buttons $\rightarrow$ **Sistema de Amortización**
    * `col-md-6`: Input Numérico $\rightarrow$ **Periodos de Gracia Totales ($g$)** *(Valor por defecto: 0)*.
---
# Diseño Arquitectónico: Capitalización y Exportación de Reportes (HU-05 y HU-06)

## 1. Definición de Roles

### Frontend (Blazor + Bootstrap)
* **Responsabilidad UI:** Añadir un campo para capturar los "Periodos de Gracia" en el formulario de parametrización. Añadir botones de "Descargar PDF" y "Descargar Excel" en la vista donde se renderiza la tabla.
* **Responsabilidad Lógica:** Al solicitar un reporte, Blazor debe manejar la recepción de un archivo (flujo de bytes o *stream*) desde el backend e invocar al navegador del usuario (mediante interoperabilidad con JavaScript - *JS Interop*) para que aparezca la ventana de "Guardar archivo como...".

### Backend (.NET Web API)
* **Responsabilidad Lógica (Capitalización):** Modificar el motor matemático para que, antes de amortizar, calcule los intereses de los periodos de gracia y los sume al capital inicial (Interés Compuesto).
* **Responsabilidad de Archivos (Exportación):** Recibir los parámetros del crédito, generar el reporte en memoria utilizando librerías de .NET (como `iText7` o `QuestPDF` para PDF, y `ClosedXML` o `EPPlus` para Excel), y devolver un archivo binario al frontend. Al ser "Stateless", el archivo se crea en la memoria RAM, se envía y se destruye inmediatamente; no se guarda nada en el disco del servidor.

---

## 2. Diseño del Backend (.NET)

### A. Clases de Modelo (DTOs)

1. **`AmortizacionRequestDto` (Actualizado para HU-05):**
   * `Capital` (decimal)
   * `Plazo` (int)
   * `TasaEfectivaPeriodica` (decimal)
   * `SistemaAmortizacion` (Enum: Frances, Aleman)
   * **`PeriodosGracia` (int)** $\rightarrow$ *¡Nueva variable! Por defecto será 0.*

2. **`ExportarReporteRequestDto` (Para HU-06):**
   * Hereda o contiene el mismo `AmortizacionRequestDto` (para saber qué recalcular).
   * `FormatoExportacion` (Enum: PDF, Excel) - *Para que el backend sepa qué tipo de archivo construir.*

### B. Capa de Servicios (Lógica de Negocio)

1. **`ServicioAmortizacion` (Actualizado para HU-05):**
   * **Nueva Lógica (Fase 1 - Gracia):** Si `PeriodosGracia > 0`, el motor hace un primer ciclo `for` desde $1$ hasta $g$. En este ciclo:
     * `ValorCuota` = 0.
     * `Interes` = Saldo Anterior $\times$ $i$.
     * `AbonoCapital` = 0.
     * `SaldoFinal` = Saldo Anterior + `Interes` (Aquí ocurre la capitalización).
   * **Fase 2 - Amortización Regular:** Terminado el periodo de gracia, el `SaldoFinal` actual se convierte en el nuevo Capital para calcular la cuota fija (Francés) o el abono constante (Alemán) por los periodos restantes ($n$).

2. **`ServicioReportes` (o `IReporteService` - Nuevo para HU-06):**
   * **Método:** `GenerarReporteAmortizacion(ExportarReporteRequestDto request)`
   * **Lógica:** Llama internamente a `ServicioAmortizacion.GenerarTabla()` para obtener los datos matemáticos frescos. Luego, formatea esos datos en una tabla de Excel o un documento PDF (con logos, encabezados y los totales) y retorna un arreglo de bytes (`byte[]`).

### C. Endpoints (Controladores API)

* **Ruta (Actualizada):** `POST /api/simulador/generar-tabla` $\rightarrow$ Ahora procesa los periodos de gracia.
* **Nueva Ruta:** `POST /api/simulador/exportar-reporte`
  * **Acción:** Recibe los datos de configuración, llama al `ServicioReportes`, y en lugar de devolver un JSON, devuelve un `FileResult` (por ejemplo, `application/pdf` o `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`).

---

## 3. Diseño del Frontend (Blazor)

### A. Servicios de Integración (API Client)
1. **`SimuladorApiClient`:**
   * **Nuevo Método:** `DescargarReporteAsync(ExportarReporteRequestDto request)`
   * **Lógica:** Hace el POST a `/api/simulador/exportar-reporte`, lee la respuesta como un `Stream` o `byte[]` y se lo pasa a una función de ayuda de JavaScript.

### B. Estado de la Vista (Componente de Blazor)
* **Actualización UI (Tarjeta 3):**
  * Agregamos el `col-md-6` con el Input Numérico para los **Periodos de Gracia**, mapeado con `@bind-Value="request.PeriodosGracia"`.
* **Actualización UI (Resultados):**
  * Debajo o al lado del resumen de totales, se agregan dos botones:
    * `<button class="btn btn-danger"> <i class="bi bi-file-pdf"></i> Descargar PDF </button>`
    * `<button class="btn btn-success"> <i class="bi bi-file-excel"></i> Descargar Excel </button>`
* **Interactividad (Descargas):**
  * Los botones tendrán un evento `@onclick` que empaqueta los datos actuales del formulario, indica el formato deseado, y llama al backend.
  * *Nota técnica para tus desarrolladores:* Necesitarán invocar una pequeña función de JavaScript usando `IJSRuntime` para crear un enlace de descarga temporal (`<a>`) en el navegador, pasarle los bytes del archivo y forzar el clic para que el archivo se guarde en la computadora del estudiante.