using EconomicApp.Models.DTOs;

namespace EconomicApp.Models.DTOs;

public class ExportarReporteRequestDto
{
    public AmortizacionRequestDto ParametrosCredito { get; set; } = new();
    public FormatoExportacion FormatoExportacion { get; set; }
}