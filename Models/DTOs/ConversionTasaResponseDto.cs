namespace EconomicApp.Models.DTOs;

public class ConversionTasaResponseDto
{
    public decimal TasaEfectivaPeriodica { get; set; }
    public bool EsExitoso { get; set; }
    public string Mensaje { get; set; } = string.Empty;
}