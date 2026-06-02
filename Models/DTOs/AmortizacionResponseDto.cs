namespace EconomicApp.Models.DTOs;

public class AmortizacionResponseDto
{
    public List<CuotaDto> TablaAmortizacion { get; set; } = new();
    public decimal TotalInteresesPagados { get; set; }
    public decimal TotalPagado { get; set; }
}