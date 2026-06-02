using EconomicApp.Models.DTOs;
using System;

namespace EconomicApp.Services
{
    public class ServicioConversorTasas : ITasaService
    {
        private const int DECIMALES_PRECISION = 10;

        public ConversionTasaResponseDto CalcularTasaPeriodica(SimulacionRequestDto request)
        {
            var respuesta = new ConversionTasaResponseDto { EsExitoso = false };

            try
            {
                if (request.MontoPrestamo <= 0 || request.Plazo <= 0 || request.ValorTasa <= 0)
                {
                    respuesta.Mensaje = "Los valores de monto, plazo y tasa deben ser mayores a cero.";
                    return respuesta;
                }

                decimal tasaConvertida;
                // Necesitamos rastrear cuál es la base de la tasa que vamos a usar en la equivalencia
                Frecuencia frecuenciaOrigen;

                if (request.TipoTasa == TipoTasa.Nominal)
                {
                    // La fórmula matemática siempre convierte la Nominal en una Efectiva Anual (EA)
                    tasaConvertida = ConvertirNominalAEfectiva(request.ValorTasa, request.FrecuenciaTasa);

                    // Como ahora es Efectiva Anual, su frecuencia de origen es 1 (Anual)
                    // Nota: Asegúrate de que tu Enum 'Frecuencia' tenga 'Anual = 1'. Si no, usa (Frecuencia)1
                    frecuenciaOrigen = (Frecuencia)1;
                }
                else
                {
                    // Si ya ingresó una efectiva, la usamos tal cual con su frecuencia original
                    tasaConvertida = request.ValorTasa / 100;
                    frecuenciaOrigen = request.FrecuenciaTasa;
                }

                // Finalmente calculamos la equivalencia hacia la frecuencia de PAGO
                decimal tasaPeriodica = EquivalenciaTasas(tasaConvertida, frecuenciaOrigen, request.FrecuenciaPago);

                respuesta.TasaEfectivaPeriodica = Math.Round(tasaPeriodica, DECIMALES_PRECISION);
                respuesta.EsExitoso = true;
                respuesta.Mensaje = $"Tasa convertida exitosamente a tasa efectiva periódica ({request.FrecuenciaPago}).";
            }
            catch (Exception ex)
            {
                respuesta.Mensaje = $"Error en el cálculo: {ex.Message}";
            }

            return respuesta;
        }

        private decimal ConvertirNominalAEfectiva(decimal tasaNominal, Frecuencia frecuenciaTasa)
        {
            int m = (int)frecuenciaTasa;
            decimal tasaNominalDecimal = tasaNominal / 100;
            // Retorna siempre una Tasa Efectiva Anual (EA)
            decimal tasaEfectiva = (decimal)Math.Pow((double)(1 + tasaNominalDecimal / m), m) - 1;
            return Math.Round(tasaEfectiva, DECIMALES_PRECISION);
        }

        private decimal EquivalenciaTasas(decimal tasaConocida, Frecuencia frecuenciaOrigen, Frecuencia frecuenciaDestino)
        {
            if (frecuenciaOrigen == frecuenciaDestino)
                return tasaConocida;

            decimal n1 = (int)frecuenciaOrigen;
            decimal n2 = (int)frecuenciaDestino;

            // SOLUCIÓN AL BUG: El exponente es (Origen / Destino)
            // Ejemplo: De Anual (1) a Trimestral (4) => Factor = 1/4 = 0.25 (Raíz cuarta)
            decimal factor = n1 / n2;
            decimal tasaEquivalente = (decimal)Math.Pow((double)(1 + tasaConocida), (double)factor) - 1;

            return Math.Round(tasaEquivalente, DECIMALES_PRECISION);
        }
    }
}