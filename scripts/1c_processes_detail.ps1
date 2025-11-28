param(
    [string]$Port = $args[0],      # Порт процесса 1С
    [string]$Metric = $args[1]    # Запрашиваемая метрика
)

function Get-ProcessMetric {
    param (
        [hashtable]$ProcessData,
        [string]$Metric
    )

    switch ($Metric) {
        "connections" {
            return Parse-IntegerValue -Data $ProcessData -Key "connections"
        }
        "memory_size" {
            return Parse-MemoryValue -Data $ProcessData -Key "memory-size"
        }
        "avg_call_time" {
            return Parse-FloatValue -Data $ProcessData -Key "avg-call-time"
        }
        "avg_db_call_time" {
            return Parse-FloatValue -Data $ProcessData -Key "avg-db-call-time"
        }
        "avg_lock_call_time" {
            return Parse-FloatValue -Data $ProcessData -Key "avg-lock-call-time"
        }
        "avg_server_call_time" {
            return Parse-FloatValue -Data $ProcessData -Key "avg-server-call-time"
        }
        "available_perfomance" {
            return Parse-IntegerValue -Data $ProcessData -Key "available-perfomance"
        }
        "windows_memory" {
            return Get-WindowsMemory -ProcessData $ProcessData
        }
        default {
            return 0
        }
    }
}

function Parse-IntegerValue {
    param (
        [hashtable]$Data,
        [string]$Key
    )
    if ($Data.ContainsKey($Key) -and $Data[$Key] -match '^\d+$') {
        return [int]$Data[$Key]
    }
    return 0
}

function Parse-FloatValue {
    param (
        [hashtable]$Data,
        [string]$Key
    )
    if ($Data.ContainsKey($Key) -and $Data[$Key] -match '^\d+(\.\d+)?$') {
        $value = [double]$Data[$Key]
        return $value.ToString("F", [cultureinfo]::InvariantCulture)
    }
    return 0
}

function Parse-MemoryValue {
    param (
        [hashtable]$Data,
        [string]$Key
    )
    if ($Data.ContainsKey($Key) -and $Data[$Key] -match '^\d+$') {
        $value = [math]::Round([long]$Data[$Key] / 1MB, 2)
        return $value.ToString("F", [cultureinfo]::InvariantCulture)
    }
    return 0
}

function Get-WindowsMemory {
    param (
        [hashtable]$ProcessData
    )
    if ($ProcessData.ContainsKey("pid") -and $ProcessData["pid"] -match '^\d+$') {
        $ProcessID = [int]$ProcessData["pid"]
        $process = Get-Process -Id $ProcessID -ErrorAction SilentlyContinue
        if ($process) {
            $workingSet = [math]::Round($process.WorkingSet64 , 2)
            if ($workingSet -ge 1024) {
                $valueInGB = [math]::Round($workingSet / 1GB , 2)
                return $valueInGB.ToString("F", [cultureinfo]::InvariantCulture)
            } else {
                return $workingSet.ToString("F", [cultureinfo]::InvariantCulture)
            }
        }
    }
    return 0
}

try {
    # ----------------------------------------------------
    # Конфигурация RAC
    # ----------------------------------------------------
    $configPath = "C:\Program Files\Zabbix Agent\script\config\1c_config.psd1"

    if (-not (Test-Path $configPath)) {
        Write-Output 0
        return
    }

    $CONFIG_1C = Import-PowerShellDataFile -Path $configPath

    $RacPath     = $CONFIG_1C.RacPath
    $ClusterId   = $CONFIG_1C.ClusterId
    $ClusterUser = $CONFIG_1C.ClusterUser
    $ClusterPwd  = $CONFIG_1C.ClusterPwd
    $Server      = $CONFIG_1C.Server

    if (-not $Port -or -not $Metric) {
        Write-Output 0
        return
    }

    # ----------------------------------------------------
    # Получение данных процессов 1С через rac
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

    if ($currentProcess.Count -gt 0 -and $currentProcess.port -eq $Port) {
        $processData = $currentProcess.Clone()
    }

    if ($processData.Count -eq 0) {
        Write-Output 0
        return
    }

    # ----------------------------------------------------
    # Получение метрики
    # ----------------------------------------------------
    Write-Output (Get-ProcessMetric -ProcessData $processData -Metric $Metric)
}
catch {
    Write-Output ("Error in metric '{0}' for port '{1}': {2}" -f $Metric, $Port, $_)
}