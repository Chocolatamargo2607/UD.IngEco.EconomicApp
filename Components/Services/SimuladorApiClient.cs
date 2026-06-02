using System.Net.Http.Json;
using EconomicApp.Models.DTOs;

namespace EconomicApp.Components.Services;

public class SimuladorApiClient
{
    private readonly HttpClient _httpClient;

    public SimuladorApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<ConversionTasaResponseDto> ObtenerTasaConvertidaAsync(SimulacionRequestDto request)
    {
        var respuesta = await _httpClient.PostAsJsonAsync("api/simulador/convertir-tasa", request);
        respuesta.EnsureSuccessStatusCode();
        return await respuesta.Content.ReadFromJsonAsync<ConversionTasaResponseDto>() 
            ?? new ConversionTasaResponseDto { EsExitoso = false, Mensaje = "Error al procesar la respuesta" };
    }

    public async Task<AmortizacionResponseDto> ObtenerTablaAmortizacionAsync(AmortizacionRequestDto request)
    {
        var respuesta = await _httpClient.PostAsJsonAsync("api/simulador/generar-tabla", request);
        respuesta.EnsureSuccessStatusCode();
        return await respuesta.Content.ReadFromJsonAsync<AmortizacionResponseDto>() 
            ?? new AmortizacionResponseDto();
    }

    public async Task<byte[]> DescargarReporteAsync(ExportarReporteRequestDto request)
    {
        var respuesta = await _httpClient.PostAsJsonAsync("api/simulador/exportar-reporte", request);
        respuesta.EnsureSuccessStatusCode();
        return await respuesta.Content.ReadAsByteArrayAsync();
    }
}