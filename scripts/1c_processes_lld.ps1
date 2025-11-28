param($Metric = $args[0])

try {
    # ----------------------------------------------------
    # Путь к конфигу
    # ----------------------------------------------------
    $configPath = "C:\Program Files\Zabbix Agent\script\config\1c_config.psd1"

    # Проверка существования конфигурации
    if (-not (Test-Path $configPath)) {
        Write-Output '{"data":[]}'
        exit
    }

    # Загружаем конфигурацию
    $CONFIG_1C = Import-PowerShellDataFile -Path $configPath

    # Подготовка переменных
    $RacPath = $CONFIG_1C.RacPath
    $ClusterId = $CONFIG_1C.ClusterId
    $ClusterUser = $CONFIG_1C.ClusterUser
    $ClusterPwd = $CONFIG_1C.ClusterPwd
    $Server = $CONFIG_1C.Server


    # ----------------------------------------------------
    # LLD discovery
    # ----------------------------------------------------
    if ($Metric -eq "discovery") {

        $result = & $RacPath process list --cluster=$ClusterId --cluster-user=$ClusterUser --cluster-pwd=$ClusterPwd $Server 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result -ne $null) {

            $processes = @()
            $currentProcess = @{}

            foreach ($line in $result) {
                if ($line -eq $null) { continue }
                $line = $line.Trim()

                # конец блока одного процесса
                if ($line -eq "" -and $currentProcess.Count -gt 0) {

                    if ($currentProcess.process -and $currentProcess.port) {

                        $lldObject = @{
                            "{#HOST}"                 = if ($currentProcess.ContainsKey("host")) { $currentProcess["host"] } else { "unknown" }
                            "{#PORT}"                 = if ($currentProcess.ContainsKey("port")) { $currentProcess["port"] } else { "0" }
                            "{#PID}"                  = if ($currentProcess.ContainsKey("pid")) { $currentProcess["pid"] } else { "0" }
                            "{#TURNED_ON}"            = if ($currentProcess.ContainsKey("turned-on")) { $currentProcess["turned-on"] } else { "unknown" }
                            "{#RUNNING}"              = if ($currentProcess.ContainsKey("running")) { $currentProcess["running"] } else { "unknown" }
                            "{#STARTED_AT}"           = if ($currentProcess.ContainsKey("started-at")) { $currentProcess["started-at"] } else { "unknown" }
                            "{#USE}"                  = if ($currentProcess.ContainsKey("use")) { $currentProcess["use"] } else { "unknown" }
                            "{#AVAILABLE_PERFOMANCE}" = if ($currentProcess.ContainsKey("available-perfomance")) { $currentProcess["available-perfomance"] } else { "0" }
                            "{#CAPACITY}"             = if ($currentProcess.ContainsKey("capacity")) { $currentProcess["capacity"] } else { "0" }
                            "{#CONNECTIONS}"          = if ($currentProcess.ContainsKey("connections")) { $currentProcess["connections"] } else { "0" }
                            "{#MEMORY_SIZE}"          = if ($currentProcess.ContainsKey("memory-size")) { $currentProcess["memory-size"] } else { "0" }
                            "{#AVG_CALL_TIME}"        = if ($currentProcess.ContainsKey("avg-call-time")) { $currentProcess["avg-call-time"] } else { "0" }
                            "{#AVG_DB_CALL_TIME}"     = if ($currentProcess.ContainsKey("avg-db-call-time")) { $currentProcess["avg-db-call-time"] } else { "0" }
                            "{#AVG_LOCK_CALL_TIME}"   = if ($currentProcess.ContainsKey("avg-lock-call-time")) { $currentProcess["avg-lock-call-time"] } else { "0" }
                            "{#AVG_SERVER_CALL_TIME}" = if ($currentProcess.ContainsKey("avg-server-call-time")) { $currentProcess["avg-server-call-time"] } else { "0" }
                        }

                        $processes += $lldObject
                    }

                    $currentProcess = @{}
                }
                elseif ($line -match "^([\w-]+)\s*:\s*(.+)") {
                    $key = $matches[1].Trim()
                    $value = $matches[2].Trim()
                    $currentProcess[$key] = $value
                }
            }

            # добавление последнего блока
            if ($currentProcess.process -and $currentProcess.port) {
                $lldObject = @{
                    "{#HOST}"                 = if ($currentProcess.ContainsKey("host")) { $currentProcess["host"] } else { "unknown" }
                    "{#PORT}"                 = if ($currentProcess.ContainsKey("port")) { $currentProcess["port"] } else { "0" }
                    "{#PID}"                  = if ($currentProcess.ContainsKey("pid")) { $currentProcess["pid"] } else { "0" }
                    "{#TURNED_ON}"            = if ($currentProcess.ContainsKey("turned-on")) { $currentProcess["turned-on"] } else { "unknown" }
                    "{#RUNNING}"              = if ($currentProcess.ContainsKey("running")) { $currentProcess["running"] } else { "unknown" }
                    "{#STARTED_AT}"           = if ($currentProcess.ContainsKey("started-at")) { $currentProcess["started-at"] } else { "unknown" }
                    "{#USE}"                  = if ($currentProcess.ContainsKey("use")) { $currentProcess["use"] } else { "unknown" }
                    "{#AVAILABLE_PERFOMANCE}" = if ($currentProcess.ContainsKey("available-perfomance")) { $currentProcess["available-perfomance"] } else { "0" }
                    "{#CAPACITY}"             = if ($currentProcess.ContainsKey("capacity")) { $currentProcess["capacity"] } else { "0" }
                    "{#CONNECTIONS}"          = if ($currentProcess.ContainsKey("connections")) { $currentProcess["connections"] } else { "0" }
                    "{#MEMORY_SIZE}"          = if ($currentProcess.ContainsKey("memory-size")) { $currentProcess["memory-size"] } else { "0" }
                    "{#AVG_CALL_TIME}"        = if ($currentProcess.ContainsKey("avg-call-time")) { $currentProcess["avg-call-time"] } else { "0" }
                    "{#AVG_DB_CALL_TIME}"     = if ($currentProcess.ContainsKey("avg-db-call-time")) { $currentProcess["avg-db-call-time"] } else { "0" }
                    "{#AVG_LOCK_CALL_TIME}"   = if ($currentProcess.ContainsKey("avg-lock-call-time")) { $currentProcess["avg-lock-call-time"] } else { "0" }
                    "{#AVG_SERVER_CALL_TIME}" = if ($currentProcess.ContainsKey("avg-server-call-time")) { $currentProcess["avg-server-call-time"] } else { "0" }
                }

                $processes += $lldObject
            }

            $json = @{ data = $processes } | ConvertTo-Json -Compress
            Write-Output $json
        }
        else {
            Write-Output '{"data":[]}'
        }
    }
    else {
        Write-Output '{"data":[]}'
    }
}
catch {
    Write-Output '{"data":[]}'
}
