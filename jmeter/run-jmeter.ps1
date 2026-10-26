# =============================================================================
# CMCKO — JMeter Load Generator Runner (PowerShell for Windows)
# =============================================================================
param (
    [string]$TargetHost = "localhost",
    [string]$TargetPort = "30080",
    [int]$Threads = 35,
    [int]$Duration = 300,
    [int]$RampUp = 15,
    [int]$ThinkTime = 200
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$JmxFile = Join-Path $ScriptDir "cmcko-traffic-test.jmx"
$LogDir = Join-Path $ScriptDir "results"
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ResultFile = Join-Path $LogDir "run_$Timestamp.jtl"

Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  CMCKO Traffic Generator: Flash Spike Load Test (Windows)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Target Host:       $TargetHost"
Write-Host "  Target Port:       $TargetPort"
Write-Host "  Virtual Users:     $Threads threads"
Write-Host "  Duration:          $Duration seconds"
Write-Host "  Think Time:        ${ThinkTime} ms"
Write-Host "  Test Plan:         $JmxFile"
Write-Host "  Results:           $ResultFile"
Write-Host "═══════════════════════════════════════════════════════════════════"

if (Get-Command jmeter -ErrorAction SilentlyContinue) {
    jmeter -n `
        -t "$JmxFile" `
        -Jtarget.host="$TargetHost" `
        -Jtarget.port="$TargetPort" `
        -Jthreads="$Threads" `
        -Jduration="$Duration" `
        -Jrampup="$RampUp" `
        -Jthinktime="$ThinkTime" `
        -l "$ResultFile"
} else {
    Write-Host ""
    Write-Host "⚠️  JMeter CLI not found in PATH." -ForegroundColor Yellow
    Write-Host "Run using Docker without installing JMeter:" -ForegroundColor Green
    Write-Host "docker run --rm -i -v ${ScriptDir}:/jmeter justb4/jmeter:latest -n -t /jmeter/cmcko-traffic-test.jmx -Jtarget.host=$TargetHost -Jtarget.port=$TargetPort -Jthreads=$Threads -Jduration=$Duration -Jrampup=$RampUp -Jthinktime=$ThinkTime"
}
