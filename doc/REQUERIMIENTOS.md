# Documento de Especificación de Requerimientos (Actualizado)
**Proyecto:** EconomicApp - Simulador de Créditos Académico  
**Asignatura:** Ingeniería Económica  

## 1. Introducción
El presente documento define los requerimientos funcionales y no funcionales para el desarrollo de un simulador de créditos simplificado. El objetivo es proporcionar una herramienta educativa que permita a los estudiantes de Ingeniería Económica modelar préstamos, convertir tasas, calcular capitalizaciones y exportar reportes de amortización.

---

## 2. Requerimientos Funcionales (RF)

* **RF-01: Configuración de Parámetros de Crédito** El sistema debe permitir al usuario ingresar el capital (monto), el plazo (número de periodos) y la periodicidad del pago (mensual, trimestral, semestral, anual).

* **RF-02: Gestión de Tasas de Interés** El sistema debe permitir la entrada de tasas Nominales y Efectivas, permitiendo al usuario especificar la periodicidad de capitalización.

* **RF-03: Motor de Conversión de Tasas** El software debe calcular automáticamente la tasa efectiva periódica equivalente que corresponda a la frecuencia de los pagos definida por el usuario.

* **RF-04: Generación de Tabla de Amortización** El sistema debe generar una tabla dinámica que muestre el desglose de cuota, interés, abono a capital y saldo pendiente para cada periodo.

* **RF-05: Comparación de Sistemas de Amortización** El usuario debe poder elegir entre el Sistema Francés (Cuota Fija) y el Sistema Alemán (Abono Constante a Capital) para comparar el comportamiento del crédito.

* **RF-06: Motor de Capitalización y Periodos de Gracia (NUEVO)** El sistema debe permitir configurar la frecuencia de capitalización del interés compuesto. Además, debe contemplar la opción de agregar "periodos de gracia muertos", donde los intereses generados no se pagan, sino que se *capitalizan* (se suman al saldo del capital principal) antes de iniciar la amortización regular.

* **RF-07: Reportes de Amortización (NUEVO)** El sistema debe contar con un módulo de exportación que genere un reporte consolidado del crédito. Este reporte debe incluir los parámetros iniciales, el resumen de totales (costo financiero) y la tabla de amortización completa en formatos portables (PDF y/o Excel/CSV).

---

## 3. Requerimientos No Funcionales (RNF)

* **Usabilidad:** La interfaz debe ser intuitiva y minimalista, centrada en los datos financieros sin elementos distractores.
* **Precisión:** Los cálculos matemáticos deben manejar al menos 6 decimales de precisión interna para evitar errores de redondeo en el saldo final (el cual debe tender a cero).
* **Interoperabilidad:** Los reportes generados en formatos de hoja de cálculo (Excel/CSV) deben ser compatibles con el software estándar del mercado.
* **Disponibilidad:** Al ser una aplicación basada en la web, debe ser accesible desde cualquier navegador moderno y ser *responsive* en su uso básico.

---

## 4. Historias de Usuario (Backlog)

### HU-01: Parametrización del Préstamo
* **Como** estudiante, 
* **quiero** ingresar el monto y el tiempo de mi crédito, 
* **para** definir la base de mi simulación financiera.
* *Criterios de Aceptación:* Validación de campos numéricos positivos; selección de periodos mediante un menú desplegable. No debe permitir enviar el formulario con campos vacíos.

### HU-02: Equivalencia de Tasas
* **Como** usuario, 
* **quiero** que el sistema convierta mi tasa EA o Nominal a una tasa periódica, 
* **para** asegurar que el cálculo del interés sea matemáticamente correcto según el plazo.
* *Criterios de Aceptación:* Mostrar el valor de la tasa periódica aplicada antes de generar la tabla.

### HU-03: Visualización de la Tabla de Pagos
* **Como** deudor, 
* **quiero** ver una tabla detallada de pagos, 
* **para** planificar mi flujo de caja y entender cuánto pago de intereses totales.
* *Criterios de Aceptación:* El saldo final de la tabla en el último periodo debe ser exactamente $0.00; debe mostrar totales acumulados al final.

### HU-04: Comparativa Francés vs. Alemán
* **Como** analista, 
* **quiero** cambiar el método de amortización con un clic, 
* **para** decidir cuál sistema genera un menor pago de intereses totales.
* *Criterios de Aceptación:* Actualización instantánea de la tabla de amortización al cambiar el selector de método sin necesidad de recargar la página.

### HU-05: Escenarios de Capitalización (NUEVO)
* **Como** estudiante de ingeniería económica, 
* **quiero** poder simular periodos de gracia donde los intereses se capitalizan (se suman a la deuda inicial), 
* **para** evaluar escenarios de préstamos más complejos donde no hay pagos inmediatos.
* *Criterios de Aceptación:* Si se activa un periodo de gracia con capitalización, la tabla debe mostrar cómo el saldo inicial aumenta periodo a periodo antes de calcular y aplicar la cuota fija de amortización.

### HU-06: Descarga de Reporte de Amortización (NUEVO)
* **Como** analista financiero, 
* **quiero** un botón para descargar el resultado de mi simulación en PDF o Excel, 
* **para** poder guardar el reporte, presentarlo en trabajos académicos o analizarlo externamente.
* *Criterios de Aceptación:* El archivo exportado debe incluir un encabezado claro con el monto, tasa efectiva periódica utilizada y plazo original, seguido de la tabla completa y los totales acumulados.