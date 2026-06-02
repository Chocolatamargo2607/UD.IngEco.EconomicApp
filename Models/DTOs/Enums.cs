namespace EconomicApp.Models.DTOs;

public enum Frecuencia
{
    Anual = 1,
    Semestral = 2,
    Cuatrimestral = 3, // Ocurre 3 veces al año (cada 4 meses)
    Trimestral = 4,    // Ocurre 4 veces al año (cada 3 meses) <-- ¡AQUÍ ESTABA EL ERROR!
    Bimestral = 6,
    Mensual = 12,
    Quincenal = 24,
    Diaria = 360
}

public enum TipoTasa
{
    Nominal,
    Efectiva
}

public enum SistemaAmortizacion
{
    Frances,
    Aleman
}

public enum FormatoExportacion
{
    PDF,
    Excel
}