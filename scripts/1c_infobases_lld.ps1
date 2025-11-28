# Сохраните как: 1c_infobases_lld.ps1
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
        $result = & $RacPath infobase summary list --cluster=$ClusterId --cluster-user=$ClusterUser --cluster-pwd=$ClusterPwd $Server 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result -ne $null) {
            $infobases = @()
            $currentInfobase = @{}
            
            foreach ($line in $result) {
                if ($line -eq $null) { continue }
                $line = $line.Trim()
                
                if ($line -eq "" -and $currentInfobase.Count -gt 0) {
                    if ($currentInfobase.infobase -and $currentInfobase.name) {
                        $infobases += @{
                            "{#IBNAME}" = $currentInfobase.name
                            
                        }
                    }
                    $currentInfobase = @{}
                }
                elseif ($line -match "^([\w-]+)\s*:\s*(.+)") {
                    $key = $matches[1].Trim()
                    $value = $matches[2].Trim()
                    $currentInfobase[$key] = $value
                }
            }
            
            # Добавляем последнюю инфобазу
            if ($currentInfobase.infobase -and $currentInfobase.name) {
                $infobases += @{
                    "{#IBNAME}" = $currentInfobase.name
                    
                }
            }
            
            $json = @{data = $infobases} | ConvertTo-Json -Compress
            Write-Output $json
        } else {
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