# Flutter Hot Reload Helper
# Mantiene flutter run activo y escucha el archivo "reload.trigger" para hacer hot reload

$projectPath = "c:\Users\cliente\Desktop\plataforma uraba\uraba_plataforma\uraba"
$triggerFile = "$projectPath\.reload_trigger"
$restartFile = "$projectPath\.restart_trigger"

# Limpiar triggers viejos
if (Test-Path $triggerFile) { Remove-Item $triggerFile }
if (Test-Path $restartFile) { Remove-Item $restartFile }

# Iniciar flutter run con stdin redirigido
$pinfo = New-Object System.Diagnostics.ProcessStartInfo
$pinfo.FileName = "C:\Users\cliente\Downloads\flutter\bin\flutter.bat"
$pinfo.Arguments = "run -d emulator-5554"
$pinfo.WorkingDirectory = $projectPath
$pinfo.UseShellExecute = $false
$pinfo.RedirectStandardInput = $true

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $pinfo
$proc.Start() | Out-Null

Write-Host "Flutter iniciado (PID: $($proc.Id))"
Write-Host "Listo para hot reload. Esperando triggers..."

# Loop: detectar triggers y enviar comandos a flutter
while (-not $proc.HasExited) {
    if (Test-Path $triggerFile) {
        Remove-Item $triggerFile
        Write-Host "[HOT RELOAD] r"
        $proc.StandardInput.WriteLine("r")
    }
    if (Test-Path $restartFile) {
        Remove-Item $restartFile
        Write-Host "[HOT RESTART] R"
        $proc.StandardInput.WriteLine("R")
    }
    Start-Sleep -Milliseconds 300
}

Write-Host "Flutter process ended."
