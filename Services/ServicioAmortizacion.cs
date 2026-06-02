using EconomicApp.Models.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;

namespace EconomicApp.Services
{
    public class ServicioAmortizacion : IAmortizacionService
    {
        private const int DECIMALES_PRECISION = 10;

        public AmortizacionResponseDto GenerarTabla(AmortizacionRequestDto request)
        {
            var respuesta = new AmortizacionResponseDto();
            var tabla = new List<CuotaDto>();

            decimal saldoActual = request.Capital;

            // Periodo 0 (Desembolso)
            tabla.Add(new CuotaDto
            {
                NumeroPeriodo = 0,
                SaldoInicial = 0,
                Interes = 0,
                AbonoCapital = 0,
                ValorCuota = 0,
                SaldoFinal = Math.Round(saldoActual, DECIMALES_PRECISION)
            });

            if (request.PeriodosGracia > 0)
            {
                saldoActual = AplicarPeriodosGracia(tabla, saldoActual, request.TasaEfectivaPeriodica, request.PeriodosGracia);
            }

            if (request.SistemaAmortizacion == SistemaAmortizacion.Frances)
            {
                GenerarFrances(tabla, saldoActual, request.TasaEfectivaPeriodica, request.Plazo);
            }
            else
            {
                GenerarAleman(tabla, saldoActual, request.TasaEfectivaPeriodica, request.Plazo);
            }

            respuesta.TablaAmortizacion = tabla;
            respuesta.TotalInteresesPagados = Math.Round(tabla.Sum(c => c.Interes), DECIMALES_PRECISION);
            respuesta.TotalPagado = Math.Round(tabla.Sum(c => c.ValorCuota), DECIMALES_PRECISION);

            return respuesta;
        }

        private decimal AplicarPeriodosGracia(List<CuotaDto> tabla, decimal saldo, decimal tasa, int periodosGracia)
        {
            for (int i = 0; i < periodosGracia; i++)
            {
                // SOLUCIÓN AL BUG DE ÍNDICES: tabla.Count siempre da el siguiente periodo exacto
                int periodoActual = tabla.Count;
                decimal interes = Math.Round(saldo * tasa, DECIMALES_PRECISION);
                decimal saldoFinal = Math.Round(saldo + interes, DECIMALES_PRECISION);

                tabla.Add(new CuotaDto
                {
                    NumeroPeriodo = periodoActual,
                    SaldoInicial = Math.Round(saldo, DECIMALES_PRECISION),
                    Interes = interes,
                    AbonoCapital = 0,
                    ValorCuota = 0,
                    SaldoFinal = saldoFinal
                });

                saldo = saldoFinal;
            }

            return saldo;
        }

        private void GenerarFrances(List<CuotaDto> tabla, decimal capital, decimal tasa, int plazo)
        {
            decimal cuotaFija = 0;

            // Prevención de división por cero
            if (tasa == 0)
            {
                cuotaFija = Math.Round(capital / plazo, DECIMALES_PRECISION);
            }
            else
            {
                cuotaFija = Math.Round(capital * (tasa / (1 - (decimal)Math.Pow((double)(1 + tasa), -(double)plazo))), DECIMALES_PRECISION);
            }

            decimal saldo = capital;

            for (int i = 0; i < plazo; i++)
            {
                int periodoActual = tabla.Count;
                decimal saldoInicial = Math.Round(saldo, DECIMALES_PRECISION);
                decimal interes = Math.Round(saldo * tasa, DECIMALES_PRECISION);

                decimal amortizacion;
                decimal cuotaActual;

                if (i == plazo - 1)
                {
                    // ÚLTIMO PERIODO: La amortización absorbe exactamente el saldo anterior
                    amortizacion = saldoInicial;
                    cuotaActual = Math.Round(amortizacion + interes, DECIMALES_PRECISION);
                    saldo = 0; // Forzamos el cierre a 0 de forma estricta
                }
                else
                {
                    cuotaActual = cuotaFija;
                    amortizacion = Math.Round(cuotaActual - interes, DECIMALES_PRECISION);
                    saldo = Math.Round(saldo - amortizacion, DECIMALES_PRECISION);
                }

                tabla.Add(new CuotaDto
                {
                    NumeroPeriodo = periodoActual,
                    SaldoInicial = saldoInicial,
                    Interes = interes,
                    AbonoCapital = amortizacion,
                    ValorCuota = cuotaActual,
                    SaldoFinal = saldo
                });
            }
        }

        private void GenerarAleman(List<CuotaDto> tabla, decimal capital, decimal tasa, int plazo)
        {
            decimal saldo = capital;
            decimal abonoFijo = Math.Round(capital / plazo, DECIMALES_PRECISION);

            for (int i = 0; i < plazo; i++)
            {
                int periodoActual = tabla.Count;
                decimal saldoInicial = Math.Round(saldo, DECIMALES_PRECISION);
                decimal interes = Math.Round(saldo * tasa, DECIMALES_PRECISION);

                decimal amortizacion;
                decimal cuotaActual;

                if (i == plazo - 1)
                {
                    // ÚLTIMO PERIODO: La amortización absorbe exactamente el saldo anterior
                    amortizacion = saldoInicial;
                    cuotaActual = Math.Round(amortizacion + interes, DECIMALES_PRECISION);
                    saldo = 0; // Forzamos el cierre a 0 de forma estricta
                }
                else
                {
                    amortizacion = abonoFijo;
                    cuotaActual = Math.Round(amortizacion + interes, DECIMALES_PRECISION);
                    saldo = Math.Round(saldo - amortizacion, DECIMALES_PRECISION);
                }

                tabla.Add(new CuotaDto
                {
                    NumeroPeriodo = periodoActual,
                    SaldoInicial = saldoInicial,
                    Interes = interes,
                    AbonoCapital = amortizacion,
                    ValorCuota = cuotaActual,
                    SaldoFinal = saldo
                });
            }
        }
        public AmortizacionResponseDto RecalcularDesdePeriodo(List<CuotaDto> tablaOriginal, int periodo, decimal abono,TipoRecalculo tipo, decimal tasa, SistemaAmortizacion sistema){
            var nuevaTabla = new List<CuotaDto>();

            var cuotasAnteriores = tipo == TipoRecalculo.RecalcularCuota
                ? tablaOriginal.Where(x => x.NumeroPeriodo < periodo).ToList()
                : tablaOriginal.Where(x => x.NumeroPeriodo <= periodo).ToList();
            
            //var cuotasAnteriores = tablaOriginal.Where(x => x.NumeroPeriodo <= periodo).ToList();

            nuevaTabla.AddRange(cuotasAnteriores);

            var cuotaBase = tablaOriginal.First(x => x.NumeroPeriodo == periodo);

            decimal nuevoSaldo = tipo == TipoRecalculo.RecalcularCuota
                ? cuotaBase.SaldoFinal
                : cuotaBase.SaldoFinal - abono;

            if (nuevoSaldo < 0)
                nuevoSaldo = 0;

            int cuotasRestantes = tipo == TipoRecalculo.RecalcularCuota
                ? tablaOriginal.Count - periodo
                : tablaOriginal.Count - periodo - 1;
            
            //int cuotasRestantes = tablaOriginal.Count - periodo - 1;
            Console.WriteLine($"DEBUG cuotasRestantes: {cuotasRestantes}");
            Console.WriteLine($"DEBUG nuevaTabla antes de generar: {nuevaTabla.Count}");

            // Metodo 1:
            // Reducir cuota
            if (tipo == TipoRecalculo.RecalcularCuota){
                Console.WriteLine($"DEBUG - periodo: {periodo}");
                Console.WriteLine($"DEBUG - SaldoInicial: {cuotaBase.SaldoInicial}");
                Console.WriteLine($"DEBUG - cuotasRestantes: {cuotasRestantes}");
                Console.WriteLine($"DEBUG - tablaOriginal.Count: {tablaOriginal.Count}");
                if (sistema == SistemaAmortizacion.Frances)
                    GenerarFrances(nuevaTabla, nuevoSaldo, tasa, cuotasRestantes);
                else
                    GenerarAleman(nuevaTabla, nuevoSaldo, tasa, cuotasRestantes);
            }
            // Metodo 2:
            // Mantener cuota y reducir plazo
            else{
                if (abono > 0)
                {
                    var cuotaPeriodo = nuevaTabla.First(x => x.NumeroPeriodo == periodo);
                    cuotaPeriodo.AbonoExtraordinario = abono;
                    cuotaPeriodo.SaldoFinal = Math.Round(nuevoSaldo, DECIMALES_PRECISION);
                }

                decimal cuotaOriginal = tablaOriginal
                    .First(x => x.NumeroPeriodo == periodo + 1)
                    .ValorCuota;

                if (sistema == SistemaAmortizacion.Frances)
                    GenerarFrancesConCuotaFija(nuevaTabla, nuevoSaldo, tasa, cuotaOriginal);
                else
                    GenerarAlemanConCuotaFija(nuevaTabla, nuevoSaldo, tasa, cuotaOriginal);
            }

            return new AmortizacionResponseDto{
                TablaAmortizacion = nuevaTabla,
                TotalInteresesPagados = nuevaTabla.Sum(x => x.Interes),
                TotalPagado = nuevaTabla.Sum(x => x.ValorCuota + x.AbonoExtraordinario)
            };
        }
        private void GenerarFrancesConCuotaFija(
            List<CuotaDto> tabla,
            decimal saldoInicial,
            decimal tasa,
            decimal cuotaFija)
        {
            decimal saldo = Math.Round(saldoInicial, DECIMALES_PRECISION);

            while (saldo > 0)
            {
                int periodoActual = tabla.Count;

                decimal saldoPeriodo = saldo;

                decimal interes = Math.Round(
                    saldoPeriodo * tasa,
                    DECIMALES_PRECISION);

                decimal amortizacion = Math.Round(
                    cuotaFija - interes,
                    DECIMALES_PRECISION);

                decimal cuotaActual = cuotaFija;

                // Protección:
                // Si la cuota ya supera el saldo restante
                // cerramos completamente el crédito

                if (amortizacion >= saldoPeriodo)
                {
                    amortizacion = saldoPeriodo;

                    cuotaActual = Math.Round(
                        amortizacion + interes,
                        DECIMALES_PRECISION);

                    saldo = 0;
                }
                else
                {
                    saldo = Math.Round(
                        saldoPeriodo - amortizacion,
                        DECIMALES_PRECISION);
                }

                tabla.Add(new CuotaDto
                {
                    NumeroPeriodo = periodoActual,
                    SaldoInicial = saldoPeriodo,
                    Interes = interes,
                    AbonoCapital = amortizacion,
                    ValorCuota = cuotaActual,
                    SaldoFinal = saldo
                });
            }
        }
        private void GenerarAlemanConCuotaFija(
            List<CuotaDto> tabla,
            decimal saldoInicial,
            decimal tasa,
            decimal cuotaFija)
        {
            decimal saldo = saldoInicial;

            while (saldo > 0)
            {
                int periodoActual = tabla.Count;

                decimal saldoPeriodo = saldo;

                decimal interes = Math.Round(
                    saldoPeriodo * tasa,
                    DECIMALES_PRECISION);

                decimal amortizacion = Math.Round(
                    cuotaFija - interes,
                    DECIMALES_PRECISION);

                decimal cuotaActual = cuotaFija;

                if (amortizacion >= saldoPeriodo)
                {
                    amortizacion = saldoPeriodo;

                    cuotaActual = Math.Round(
                        amortizacion + interes,
                        DECIMALES_PRECISION);

                    saldo = 0;
                }
                else
                {
                    saldo = Math.Round(
                        saldoPeriodo - amortizacion,
                        DECIMALES_PRECISION);
                }

                tabla.Add(new CuotaDto
                {
                    NumeroPeriodo = periodoActual,
                    SaldoInicial = saldoPeriodo,
                    Interes = interes,
                    AbonoCapital = amortizacion,
                    ValorCuota = cuotaActual,
                    SaldoFinal = saldo
                });
            }
        }
    }
}