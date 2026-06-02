using System.ComponentModel.DataAnnotations;
using EconomicApp.Models.DTOs;

namespace EconomicApp.Models.DTOs;

public class SimulacionRequestDto
{
    [Required(ErrorMessage = "El monto del préstamo es obligatorio")]
    [Range(1, double.MaxValue, ErrorMessage = "El monto debe ser mayor a 0")]
    public decimal MontoPrestamo { get; set; }

    [Required(ErrorMessage = "El plazo es obligatorio")]
    [Range(1, 360, ErrorMessage = "El plazo debe estar entre 1 y 360 periodos")]
    public int Plazo { get; set; }

    public Frecuencia FrecuenciaPago { get; set; }

    [Required(ErrorMessage = "El valor de la tasa es obligatorio")]
    [Range(0.01, 100, ErrorMessage = "La tasa debe estar entre 0.01% y 100%")]
    public decimal ValorTasa { get; set; }

    public TipoTasa TipoTasa { get; set; }
    public Frecuencia FrecuenciaTasa { get; set; }
}