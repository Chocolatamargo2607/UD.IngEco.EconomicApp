using EconomicApp.Models.DTOs;

namespace EconomicApp.Services;

public interface IAmortizacionService
{
    AmortizacionResponseDto GenerarTabla(AmortizacionRequestDto request);

    AmortizacionResponseDto RecalcularDesdePeriodo(List<CuotaDto> tablaOriginal, int periodo, decimal abono, TipoRecalculo tipo, decimal tasa, SistemaAmortizacion sistema);
}