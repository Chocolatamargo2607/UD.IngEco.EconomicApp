using Microsoft.AspNetCore.Mvc;
using EconomicApp.Models.DTOs;
using EconomicApp.Services;

namespace EconomicApp.Controllers.Api;

[ApiController]
[Route("api/simulador")]
public class SimuladorController : ControllerBase
{
    private readonly ITasaService _tasaService;
    private readonly IAmortizacionService _amortizacionService;
    private readonly IReporteService _reporteService;

    public SimuladorController(
        ITasaService tasaService,
        IAmortizacionService amortizacionService,
        IReporteService reporteService)
    {
        _tasaService = tasaService;
        _amortizacionService = amortizacionService;
        _reporteService = reporteService;
    }

    [HttpPost("convertir-tasa")]
    public ActionResult<ConversionTasaResponseDto> ConvertirTasa([FromBody] SimulacionRequestDto request)
    {
        var resultado = _tasaService.CalcularTasaPeriodica(request);
        return Ok(resultado);
    }

    [HttpPost("generar-tabla")]
    public ActionResult<AmortizacionResponseDto> GenerarTabla([FromBody] AmortizacionRequestDto request)
    {
        var resultado = _amortizacionService.GenerarTabla(request);
        return Ok(resultado);
    }

    [HttpPost("exportar-reporte")]
    public ActionResult<byte[]> ExportarReporte([FromBody] ExportarReporteRequestDto request)
    {
        var parametros = request.ParametrosCredito;
        var conversionTasa = _tasaService.CalcularTasaPeriodica(new SimulacionRequestDto
        {
            MontoPrestamo = parametros.Capital,
            Plazo = parametros.Plazo,
            FrecuenciaPago = Frecuencia.Mensual,
            ValorTasa = 18,
            TipoTasa = TipoTasa.Efectiva,
            FrecuenciaTasa = Frecuencia.Anual
        });

        var amortizacion = _amortizacionService.GenerarTabla(parametros);

        var simulacion = new SimulacionRequestDto
        {
            MontoPrestamo = parametros.Capital,
            Plazo = parametros.Plazo,
            FrecuenciaPago = Frecuencia.Mensual,
            ValorTasa = parametros.TasaEfectivaPeriodica * 100,
            TipoTasa = TipoTasa.Efectiva,
            FrecuenciaTasa = Frecuencia.Anual
        };

        byte[] archivo;

        if (request.FormatoExportacion == FormatoExportacion.Excel)
        {
            archivo = _reporteService.GenerarReporteExcel(amortizacion, simulacion);
            return File(archivo, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "reporte_credito.csv");
        }
        else
        {
            archivo = _reporteService.GenerarReportePdf(amortizacion, simulacion);
            return File(archivo, "application/pdf", "reporte_credito.txt");
        }
    }
}