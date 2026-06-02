using EconomicApp.Components;
using EconomicApp.Components.Services;
using EconomicApp.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddControllers();
builder.Services.AddScoped<ITasaService, ServicioConversorTasas>();
builder.Services.AddScoped<IAmortizacionService, ServicioAmortizacion>();
builder.Services.AddScoped<IReporteService, ServicioReportes>();
builder.Services.AddHttpClient();
builder.Services.AddScoped<SimuladorApiClient>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.MapControllers();

app.Run();
