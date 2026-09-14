var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => new { Service = "{{PROJECT_NAME}}", Status = "Running" });

app.Run();
