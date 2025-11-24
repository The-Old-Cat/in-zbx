# Процессы 1С - connections, memory, CPU, call times
# Исправленная версия без проблем с param()

# Загружаем общий модуль
. "C:\Program Files\Zabbix Agent\script\1c_cache.ps1"

# Получаем аргументы из командной строки
$Metric = $args[0]
$Port = $args[1]

function Get-ProcessesData {
    $raw = Invoke-RacCommand "process" @("list")
    $processes = @()
    $current = @{}
    
    foreach ($line in $raw) {
        $line = $line.Trim()
        if ($line -eq "" -and $current.Count -gt 0) {
            if ($current.process -and $current.port) {
                $processes += [PSCustomObject]@{
                    process = $current.process
                    host = $current.host
                    port = $current.port
                    pid = [int]$current.pid
                    connections = [int]$current.connections
                    memory_size = [math]::Round([long]$current.'memory-size' / 1MB, 2)
                    avg_call_time = [double]$current.'avg-call-time'
                    avg_db_call_time = [double]$current.'avg-db-call-time'
                    avg_lock_call_time = [double]$current.'avg-lock-call-time'
                    avg_server_call_time = [double]$current.'avg-server-call-time'
                    available_performance = [int]$current.'available-perfomance'
                    capacity = [int]$current.capacity
                }
            }
            $current = @{}
        }
        elseif ($line -match "^([\w-]+)\s*:\s*(.+)$") {
            $current[$matches[1]] = $matches[2].Trim()
        }
    }
    return $processes
}

try {
    $processes = Get-CachedData "processes" { Get-ProcessesData }
    
    if ($Metric -eq "discovery") {
        $lld = $processes | ForEach-Object {
            @{
                "{#PORT}" = $_.port
                "{#HOST}" = $_.host
                "{#PID}" = $_.pid
            }
        }
        Write-Output (@{data = $lld} | ConvertTo-Json -Compress)
    }
    elseif ($Metric -eq "count") {
        Write-Output $processes.Count
    }
    elseif ($Port -and $Metric) {
        $process = $processes | Where-Object { $_.port -eq $Port }
        if ($process) {
            switch ($Metric) {
                "connections" { Write-Output $process.connections }
                "memory_size" { Write-Output $process.memory_size }
                "avg_call_time" { Write-Output $process.avg_call_time }
                "avg_db_call_time" { Write-Output $process.avg_db_call_time }
                "avg_lock_call_time" { Write-Output $process.avg_lock_call_time }
                "avg_server_call_time" { Write-Output $process.avg_server_call_time }
                "available_performance" { Write-Output $process.available_performance }
                "capacity" { Write-Output $process.capacity }
                default { Write-Output 0 }
            }
        } else {
            Write-Output 0
        }
    }
    else {
        Write-Output 0
    }
}
catch {
    Write-Output 0
}