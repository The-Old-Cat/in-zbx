# Сохраните как: 1c_processes_detail.ps1
param(
    [string]$Port = $args[0],
    [string]$Metric = $args[1]
)

try {
    # ----------------------------------------------------
    # Путь к конфигу
    # ----------------------------------------------------
    $configPath = "C:\Program Files\Zabbix Agent\script\config\1c_config.psd1"

    # Проверка конфигурации
    if (-not (Test-Path $configPath)) {
        Write-Output 0
        return
    }

    # Загружаем параметры RAC
    $CONFIG_1C = Import-PowerShellDataFile -Path $configPath

    $RacPath     = $CONFIG_1C.RacPath
    $ClusterId   = $CONFIG_1C.ClusterId
    $ClusterUser = $CONFIG_1C.ClusterUser
    $ClusterPwd  = $CONFIG_1C.ClusterPwd
    $Server      = $CONFIG_1C.Server

    # ----------------------------------------------------
    # Проверка обязательных параметров
    # ----------------------------------------------------
    if (-not $Port -or -not $Metric) {
        Write-Output 0
        return
    }

    # ----------------------------------------------------
    # Получение данных процессов
    # ----------------------------------------------------
    $result = & $RacPath process list --cluster=$ClusterId --cluster-user=$ClusterUser --cluster-pwd=$ClusterPwd $Server 2>$null
    
    if ($LASTEXITCODE -ne 0 -or $result -eq $null) {
        Write-Output 0
        return
    }

    $processData = @{}
    $currentProcess = @{}

    foreach ($line in $result) {
        if ($line -eq $null) { continue }
        $line = $line.Trim()

        # Конец блока процесса
        if ($line -eq "" -and $currentProcess.Count -gt 0) {
            if ($currentProcess.port -eq $Port) {
                $processData = $currentProcess.Clone()
                break
            }
            $currentProcess = @{}
        }
        elseif ($line -match "^([\w-]+)\s*:\s*(.+)") {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $currentProcess[$key] = $value
        }
    }

    # Проверка последнего блока
    if ($currentProcess.Count -gt 0 -and $currentProcess.port -eq $Port) {
        $processData = $currentProcess.Clone()
    }

    if ($processData.Count -eq 0) {
        Write-Output 0
        return
    }

    # ----------------------------------------------------
    # Метрики процесса
    # ----------------------------------------------------
    switch ($Metric) {

        "connections" {
            if ($processData.ContainsKey("connections") -and $processData["connections"] -match '^\d+$') {
                Write-Output $processData["connections"]
            } else { Write-Output 0 }
        }

       "memory_size" {
            if ($processData.ContainsKey("memory-size") -and $processData["memory-size"] -match '^\d+$') {
                # Делим на 1024 чтобы конвертировать KB в MB
                $value = [math]::Round([long]$processData["memory-size"]/1024 ,1)
                Write-Output $value.ToString("F", [cultureinfo]::InvariantCulture)
            } else { Write-Output 0 }
        }

        "avg_call_time" {
            if ($processData.ContainsKey("avg-call-time") -and $processData["avg-call-time"] -match '^\d+(\.\d+)?$') {
                $value = [double]$processData["avg-call-time"]
                Write-Output $value.ToString("F", [cultureinfo]::InvariantCulture)
            } else { Write-Output 0 }
        }

        "avg_db_call_time" {
            if ($processData.ContainsKey("avg-db-call-time") -and $processData["avg-db-call-time"] -match '^\d+(\.\d+)?$') {
                $value = [double]$processData["avg-db-call-time"]
                Write-Output $value.ToString("F", [cultureinfo]::InvariantCulture)
            } else { Write-Output 0 }
        }

        "capacity" {
            if ($processData.ContainsKey("capacity") -and $processData["capacity"] -match '^\d+$') {
                Write-Output $processData["capacity"]
            } else { Write-Output 0 }
        }

        default {
            Write-Output 0
        }
    }
}
catch {
    Write-Output 0
}
