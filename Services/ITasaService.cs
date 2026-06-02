using EconomicApp.Models.DTOs;

namespace EconomicApp.Services;

public interface ITasaService
{
    ConversionTasaResponseDto CalcularTasaPeriodica(SimulacionRequestDto request);
}