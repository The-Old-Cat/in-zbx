# 1c_tech-log_monitor_1c.ps1s1
<#
.SYNOPSIS
    Сбор статистики 1С 8.3 для Zabbix (с поддержкой LLD)
.DESCRIPTION
    Поддерживает режимы:
      - "LLD" → возвращает JSON с обнаруженными сущностями
      - "calls", "locks", "excps" → возвращает метрики в JSON
.PARAMETER Mode
    Режим: LLD, calls, locks, excps
.PARAMETER LogBaseDir
    Базовая директория логов (например, E:\1c_log)
.PARAMETER SortMode
    Сортировка для calls: count, duration, dur_avg
.PARAMETER Limit
    Макс. количество записей (принимаем как строку)
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("LLD", "calls", "locks", "excps")]
    [string]$Mode,
    
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$LogBaseDir,
    
    [Parameter(Position = 2)]
    [string]$SortMode = "count",
    
    [Parameter(Position = 3)]
    [string]$Limit = ""  # Пусто по умолчанию
)

# Устанавливаем кодировку для корректного вывода в Zabbix
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Отключаем громкие ошибки
$ErrorActionPreference = "Stop"

$SCRIPT_VERSION = "2.8 (Stable)"

# === ОБРАБОТКА ПАРАМЕТРОВ ===
$LimitInt = 25  # значение по умолчанию

if (-not [string]::IsNullOrWhiteSpace($Limit)) {
    try {
        $LimitInt = [int]$Limit
        if ($LimitInt -lt 1) { $LimitInt = 1 }
    } catch {
        $LimitInt = 25
    }
}

# Для excps значение по умолчанию — 20
if ($Mode -eq "excps" -and $Limit -eq "") {
    $LimitInt = 20
}

# === ЛОГИРОВАНИЕ (опционально) ===
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if ($env:ZABBIX_DEBUG -eq "1") {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] [$Level] $Message"
    }
}

# === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===
function Get-LogDir {
    param([string]$Base, [string]$Sub)
    $map = @{
        "calls"  = "zabbix\calls"
        "locks"  = "zabbix\locks"
        "excps"  = "zabbix\excps"
    }
    $target = $map[$Sub]
    if ($target -and (Test-Path "$Base\$target" -PathType Container)) {
        return "$Base\$target"
    }
    return $null
}

function ConvertTo-ZabbixJson {
    param([array]$Data)
    $result = @{ data = @($Data) }
    return $result | ConvertTo-Json -Compress
}

# === LLD DISCOVERY ===
function Do-LLD {
    $result = @(
        @{ "{#MODE}" = "calls"  },
        @{ "{#MODE}" = "locks"  },
        @{ "{#MODE}" = "excps" }
    )
    return ConvertTo-ZabbixJson -Data $result
}

# === DETAIL: CALLS ===
function Get-CallsDetail {
    param([string]$LogDir, [string]$SortBy = "count", [int]$TopN = 25)

    $allData = @{}
    $files = Get-ChildItem -Path $LogDir -Filter "*.log" -Recurse -ErrorAction SilentlyContinue | 
             Where-Object { $_.Length -gt 0 }

    foreach ($file in $files) {
        try {
            $stream = [System.IO.File]::OpenText($file.FullName)
            try {
                while (-not $stream.EndOfStream) {
                    $line = $stream.ReadLine()
                    if ($line -match '(?i)^\d{2}:\d{2}\.\d{6}-\d+,call,') {
                        $ctx = $null
                        $cpuTime = 0
                        $parts = $line -split ','
                        for ($i = 3; $i -lt $parts.Length; $i++) {
                            if ($parts[$i] -match '(?i)^context=([^,]+)$') {
                                $ctx = $matches[1].Trim()
                            }
                            elseif ($parts[$i] -match '(?i)^cputime=(\d+)$') {
                                $cpuTime = [double]$matches[1]
                            }
                        }

                        if ($ctx -and $cpuTime -gt 0) {
                            $dur = $cpuTime / 1000  # в миллисекундах
                            if (-not $allData.ContainsKey($ctx)) {
                                $allData[$ctx] = @{ count = 0; total = 0 }
                            }
                            $allData[$ctx].count++
                            $allData[$ctx].total += $dur
                        }
                    }
                }
            }
            finally {
                $stream.Close()
            }
        }
        catch {
            Write-Log "Error reading file $($file.FullName): $_" "ERROR"
        }
    }

    if ($allData.Count -eq 0) {
        return ConvertTo-ZabbixJson @()
    }

    $list = foreach ($k in $allData.Keys) {
        [PSCustomObject]@{
            Context     = $k
            Count       = $allData[$k].count
            TotalDur    = [math]::Round($allData[$k].total, 2)
            AvgDuration = [math]::Round($allData[$k].total / $allData[$k].count, 2)
        }
    }

    switch ($SortBy) {
        "duration" { $sorted = $list | Sort-Object TotalDur -Descending }
        "dur_avg"  { $sorted = $list | Sort-Object AvgDuration -Descending }
        default    { $sorted = $list | Sort-Object Count -Descending }
    }

    $output = foreach ($item in ($sorted | Select-Object -First $TopN)) {
        [ordered]@{
            Context      = $item.Context
            Count        = $item.Count
            TotalDur_ms  = $item.TotalDur
            AvgDur_ms    = $item.AvgDuration
        }
    }

    return ConvertTo-ZabbixJson -Data $output
}

# === DETAIL: LOCKS ===
function Get-LocksDetail {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogDir,
        [Parameter(Mandatory = $false)]
        [int]$TopN = 30
    )

    if (-not (Test-Path -Path $LogDir -PathType Container)) {
        return ConvertTo-ZabbixJson @()
    }

    $regions = @{}
    $files = Get-ChildItem -Path $LogDir -Filter "*.log" -Recurse -ErrorAction SilentlyContinue | 
             Where-Object { $_.Length -gt 0 }

    if (-not $files) {
        return ConvertTo-ZabbixJson @()
    }

    foreach ($file in $files) {
        try {
            $stream = [System.IO.File]::OpenText($file.FullName)
            try {
                while (-not $stream.EndOfStream) {
                    $line = $stream.ReadLine()
                    if ($line -match '(?i)^\d{2}:\d{2}\.\d{6}-\d+,(tlock|ttimeout|tdeadlock),') {
                        if ($line -match '(?i)regions?=([^,]+)') {
                            $reg = $matches[1].Trim()
                            if ($reg) {
                                $regions[$reg] = if ($regions.ContainsKey($reg)) { $regions[$reg] + 1 } else { 1 }
                            }
                        }
                    }
                }
            }
            finally {
                $stream.Close()
            }
        }
        catch {
            Write-Log "Error reading $($file.FullName): $_" "ERROR"
        }
    }

    $output = foreach ($entry in ($regions.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $TopN)) {
        [ordered]@{
            "{#REGION}" = $entry.Key
            "{#COUNT}"  = $entry.Value
        }
    }

    return ConvertTo-ZabbixJson -Data $output
}

# === DETAIL: EXCEPTIONS ===
function Get-ExcpsDetail {
    param([string]$LogDir, [int]$TopN = 20)

    $descrs = [System.Collections.Generic.List[string]]::new()

    $files = Get-ChildItem -Path $LogDir -Filter "*.log" -Recurse -ErrorAction SilentlyContinue | 
             Where-Object { $_.Length -gt 0 }

    foreach ($file in $files) {
        if ($descrs.Count -ge $TopN) { break }

        try {
            $stream = [System.IO.File]::OpenText($file.FullName)
            try {
                while (-not $stream.EndOfStream -and $descrs.Count -lt $TopN) {
                    $line = $stream.ReadLine()
                    if ($line -match '(?i)^\d{2}:\d{2}\.\d{6}-\d+,excp,') {
                        if ($line -match "descr='([^']+)'") {
                            $descrs.Add($matches[1])
                        }
                    }
                }
            }
            finally {
                $stream.Close()
            }
        }
        catch {
            Write-Log "Error reading $($file.FullName): $_" "ERROR"
        }
    }

    $output = for ($i = 0; $i -lt $descrs.Count; $i++) {
        [ordered]@{
            "{#INDEX}"       = $i
            "{#DESCRIPTION}" = $descrs[$i]
        }
    }

    return ConvertTo-ZabbixJson -Data $output
}

# === ГЛАВНЫЙ БЛОК ===
try {
    if ($Mode -eq "LLD") {
        Write-Output (Do-LLD)
        exit 0
    }

    $subDir = switch ($Mode) {
        "calls"  { "calls" }
        "locks"  { "locks" }
        "excps"  { "excps" }
    }

    $logDir = Get-LogDir -Base $LogBaseDir -Sub $subDir
    if (-not $logDir) {
        Write-Output (ConvertTo-ZabbixJson @())
        exit 0
    }

    $result = switch ($Mode) {
        "calls"  { Get-CallsDetail -LogDir $logDir -SortBy $SortMode -TopN $LimitInt }
        "locks"  { Get-LocksDetail -LogDir $logDir -TopN $LimitInt }
        "excps"  { Get-ExcpsDetail -LogDir $logDir -TopN $LimitInt }
    }

    Write-Output $result
}
catch {
    Write-Log "Script failed: $_" "ERROR"
    Write-Output (ConvertTo-ZabbixJson @())
    exit 1
}
