param(
    [string]$param1,
    [string]$param2
)

# === КОНФИГУРАЦИЯ ===
$racPath = "путь к rac.exe"
$clusterId = "UUID кластера"
$clusterUser = "имя пользователя администратора кластера"
$clusterPwd = "пароль администратора кластера"
$server = "localhost:1545" # порт на котором запущен 1C:Enterprise Remote Server

# Функция для выполнения RAC команд с правильным форматом параметров
function Invoke-RacCommand {
    param([string]$racCommand)
    
    try {
        # Разделяем параметры правильно
        $arguments = @(
            $racCommand,
            "list",
            "--cluster", $clusterId,
            "--cluster-user", $clusterUser,
            "--cluster-pwd", $clusterPwd,
            $server
        )
        
        $output = & $racPath $arguments 2>&1
        return $output
    }
    catch {
        return @()
    }
}

try {
    switch ($param1) {
        "locks_count" {
            $output = Invoke-RacCommand "lock"
            # В выводе RAC блокировки обозначаются как "connection", а не "lock"
            $count = ($output | Where-Object { $_ -match "^connection\s*:" }).Count
            Write-Output $count
        }
        
        "active_jobs" {
            $output = Invoke-RacCommand "backgroundjob"
            $count = ($output | Where-Object { $_ -match "^(job|background-job)\s*:" }).Count
            Write-Output $count
        }
        
        "count" {
            $output = Invoke-RacCommand "process"
            $count = ($output | Where-Object { $_ -match "^process\s*:" }).Count
            Write-Output $count
        }
        
        "discovery" {
            $output = Invoke-RacCommand "process"
            $processes = @()
            $currentProcess = @{}
            
            foreach ($line in $output) {
                $line = "$line".Trim()
                
                if ($line -eq "" -and $currentProcess.Count -gt 0) {
                    if ($currentProcess.process -and $currentProcess.port) {
                        $processes += @{
                            "{#PROCESS_ID}" = $currentProcess.process
                            "{#HOST}" = if ($currentProcess.host) { $currentProcess.host } else { "unknown" }
                            "{#PORT}" = $currentProcess.port
                        }
                    }
                    $currentProcess = @{}
                }
                elseif ($line -match "^([\w-]+)\s*:\s*(.+)$") {
                    $key = $matches[1]
                    $value = $matches[2].Trim()
                    $currentProcess[$key] = $value
                }
            }
            
            # Добавляем последний процесс
            if ($currentProcess.Count -gt 0 -and $currentProcess.process -and $currentProcess.port) {
                $processes += @{
                    "{#PROCESS_ID}" = $currentProcess.process
                    "{#HOST}" = if ($currentProcess.host) { $currentProcess.host } else { "unknown" }
                    "{#PORT}" = $currentProcess.port
                }
            }
            
            @{"data" = $processes} | ConvertTo-Json -Compress
        }
        
        "info" {
            $output = Invoke-RacCommand "process"
            $processes = @()
            $currentProcess = @{}
            
            foreach ($line in $output) {
                $line = "$line".Trim()
                
                if ($line -eq "" -and $currentProcess.Count -gt 0) {
                    $processes += $currentProcess
                    $currentProcess = @{}
                }
                elseif ($line -match "^([\w-]+)\s*:\s*(.+)$") {
                    $key = $matches[1]
                    $value = $matches[2].Trim()
                    $currentProcess[$key] = $value
                }
            }
            
            if ($currentProcess.Count -gt 0) {
                $processes += $currentProcess
            }
            
            $processes | ConvertTo-Json -Compress
        }
        
        "locks_info" {
            # Дополнительная функция для получения информации о блокировках
            $output = Invoke-RacCommand "lock"
            $locks = @()
            $currentLock = @{}
            
            foreach ($line in $output) {
                $line = "$line".Trim()
                
                if ($line -eq "" -and $currentLock.Count -gt 0) {
                    $locks += $currentLock
                    $currentLock = @{}
                }
                elseif ($line -match "^([\w-]+)\s*:\s*(.+)$") {
                    $key = $matches[1]
                    $value = $matches[2].Trim()
                    $currentLock[$key] = $value
                }
            }
            
            if ($currentLock.Count -gt 0) {
                $locks += $currentLock
            }
            
            $locks | ConvertTo-Json -Compress
        }
        
        default {
            # 1c.processes.detail[PORT, МЕТРИКА]
            if ($param1 -match "^\d+$") {
                $port = $param1
                $metric = $param2
                
                $output = Invoke-RacCommand "process"
                $currentProcess = @{}
                $found = $false
                
                foreach ($line in $output) {
                    $line = "$line".Trim()
                    
                    if ($line -eq "" -and $currentProcess.Count -gt 0) {
                        if ($currentProcess.port -eq $port) {
                            $found = $true
                            break
                        }
                        $currentProcess = @{}
                    }
                    elseif ($line -match "^([\w-]+)\s*:\s*(.+)$") {
                        $key = $matches[1]
                        $value = $matches[2].Trim()
                        $currentProcess[$key] = $value
                    }
                }
                
                if ($found -and $currentProcess.ContainsKey($metric)) {
                    Write-Output $currentProcess[$metric]
                } else {
                    Write-Output "0"
                }
            } else {
                Write-Output "0"
            }
        }
    }
}
catch {
    Write-Output "0"
}