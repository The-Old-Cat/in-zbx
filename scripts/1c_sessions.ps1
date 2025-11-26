param ($Metric = $args[0])

# Путь к конфигу
$configPath = "C:\Program Files\Zabbix Agent\script\config\1c_config.psd1"

# Проверка существования файла конфигурации
if (-not (Test-Path $configPath)) {
    Write-Output 0
    exit
}

# Загружаем конфигурацию
$CONFIG_1C = Import-PowerShellDataFile -Path $configPath

# Подготовка переменных
$Rac     = $CONFIG_1C.RacPath
$cluster = $CONFIG_1C.ClusterId
$user    = $CONFIG_1C.ClusterUser
$pwd     = $CONFIG_1C.ClusterPwd
$server  = $CONFIG_1C.Server

# Проверка существования rac.exe
if (-not (Test-Path $Rac)) {
    Write-Output 0
    exit
}

try {
    switch ($Metric) {

        # -------------------------------------------------------
        # Количество сессий
        # -------------------------------------------------------
        "count" {

            $result = & $Rac session list `
                --cluster=$cluster `
                --cluster-user=$user `
                --cluster-pwd=$pwd `
                $server 2>$null

            if ($LASTEXITCODE -ne 0 -or !$result) {
                Write-Output 0
                break
            }

            $count = ($result | Select-String "^\s*session\s*:").Count
            Write-Output $count
        }
        
        default {
            Write-Output 0
        }
    }

}
catch {
    Write-Output 0
}
