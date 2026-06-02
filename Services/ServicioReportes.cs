using System;
using System.Text;
using System.Globalization;
using EconomicApp.Models.DTOs;

namespace EconomicApp.Services;

public class ServicioReportes : IReporteService
{
    public byte[] GenerarReporteExcel(AmortizacionResponseDto amortizacion, SimulacionRequestDto parametros)
    {
        var sb = new StringBuilder();
        var cultura = CultureInfo.InvariantCulture;

        sb.AppendLine("SIMULADOR DE CREDITOS - ECONOMICAPP");
        sb.AppendLine("==================================");
        sb.AppendLine();
        sb.AppendLine("PARAMETROS DEL CREDITO");
        sb.AppendLine($"Monto del Prestamo:;{parametros.MontoPrestamo.ToString("F2", cultura)}");
        sb.AppendLine($"Plazo:;{parametros.Plazo} {parametros.FrecuenciaPago}");
        sb.AppendLine($"Valor Tasa:;{parametros.ValorTasa.ToString("F2", cultura)}%");
        sb.AppendLine($"Tipo Tasa:;{parametros.TipoTasa}");
        sb.AppendLine($"Frecuencia Tasa:;{parametros.FrecuenciaTasa}");
        sb.AppendLine("Sistema de Amortizacion:;Cuota Fija"); // Ajustable según la simulación
        sb.AppendLine("Periodos de Gracia:;0"); // Ajustable según la simulación
        sb.AppendLine();

        sb.AppendLine("RESUMEN FINANCIERO");
        sb.AppendLine($"Total Intereses:;{amortizacion.TotalInteresesPagados.ToString("F2", cultura)}");
        sb.AppendLine($"Total Pagado:;{amortizacion.TotalPagado.ToString("F2", cultura)}");
        sb.AppendLine();

        sb.AppendLine("TABLA DE AMORTIZACION");
        sb.AppendLine("Periodo;Saldo Inicial;Interes;Abono Capital;Cuota;Saldo Final");

        foreach (var cuota in amortizacion.TablaAmortizacion)
        {
            // Estandarizado a F2 y usando ; como separador
            sb.AppendLine($"{cuota.NumeroPeriodo};{cuota.SaldoInicial.ToString("F2", cultura)};{cuota.Interes.ToString("F2", cultura)};{cuota.AbonoCapital.ToString("F2", cultura)};{cuota.ValorCuota.ToString("F2", cultura)};{cuota.SaldoFinal.ToString("F2", cultura)}");
        }

        // Agregar el BOM (Byte Order Mark) para UTF-8 para arreglar los acentos en Excel
        byte[] bom = { 0xEF, 0xBB, 0xBF };
        byte[] bytesData = Encoding.UTF8.GetBytes(sb.ToString());
        byte[] bytesResultantes = new byte[bom.Length + bytesData.Length];

        Buffer.BlockCopy(bom, 0, bytesResultantes, 0, bom.Length);
        Buffer.BlockCopy(bytesData, 0, bytesResultantes, bom.Length, bytesData.Length);

        return bytesResultantes;
    }

    public byte[] GenerarReportePdf(AmortizacionResponseDto amortizacion, SimulacionRequestDto parametros)
    {
        var sb = new StringBuilder();
        var cultura = CultureInfo.InvariantCulture;

        sb.AppendLine("=== SIMULADOR DE CREDITOS ===");
        sb.AppendLine("EconomicApp - Ingenieria Economica");
        sb.AppendLine();
        sb.AppendLine("--- PARAMETROS DEL CREDITO ---");
        sb.AppendLine($"Monto: {parametros.MontoPrestamo.ToString("F2", cultura)}");
        sb.AppendLine($"Plazo: {parametros.Plazo} {parametros.FrecuenciaPago}");
        sb.AppendLine($"Tasa: {parametros.ValorTasa.ToString("F2", cultura)}% {parametros.TipoTasa}");
        sb.AppendLine("Sistema de Amortizacion: Cuota Fija");
        sb.AppendLine("Periodos de Gracia: 0");
        sb.AppendLine();
        sb.AppendLine("--- RESUMEN ---");
        sb.AppendLine($"Total Intereses: {amortizacion.TotalInteresesPagados.ToString("F2", cultura)}");
        sb.AppendLine($"Total Pagado: {amortizacion.TotalPagado.ToString("F2", cultura)}");
        sb.AppendLine();
        sb.AppendLine("--- TABLA DE AMORTIZACION ---");
        sb.AppendLine("Per|Saldo Inicial|   Interes|     Abono|     Cuota|Saldo Final");
        sb.AppendLine(new string('-', 64));

        foreach (var cuota in amortizacion.TablaAmortizacion)
        {
            // Se mejoró el padding (espaciado) para que las columnas se alineen correctamente
            sb.AppendLine($"{cuota.NumeroPeriodo,3}|{cuota.SaldoInicial,13:F2}|{cuota.Interes,10:F2}|{cuota.AbonoCapital,10:F2}|{cuota.ValorCuota,10:F2}|{cuota.SaldoFinal,11:F2}");
        }

        return Encoding.UTF8.GetBytes(sb.ToString());
    }
}