using EconomicApp.Models.DTOs;

namespace EconomicApp.Services;

public interface IReporteService
{
    byte[] GenerarReporteExcel(AmortizacionResponseDto amortizacion, SimulacionRequestDto parametros);
    byte[] GenerarReportePdf(AmortizacionResponseDto amortizacion, SimulacionRequestDto parametros);
}