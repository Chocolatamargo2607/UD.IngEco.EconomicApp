using System.ComponentModel.DataAnnotations;

namespace EconomicApp.Models.DTOs;

public class AmortizacionRequestDto
{
    public decimal Capital { get; set; }
    public int Plazo { get; set; }
    public decimal TasaEfectivaPeriodica { get; set; }
    public SistemaAmortizacion SistemaAmortizacion { get; set; }

    [Range(0, 60, ErrorMessage = "Los periodos de gracia deben estar entre 0 y 60")]
    public int PeriodosGracia { get; set; } = 0;
}