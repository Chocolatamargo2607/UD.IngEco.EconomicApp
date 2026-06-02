using EconomicApp.Models.DTOs;

namespace EconomicApp.Models.DTOs;

public class RecalculoRequestDto
{
    public int Periodo { get; set; }

    public decimal ValorAbono { get; set; }

    public TipoRecalculo Tipo { get; set; }
}