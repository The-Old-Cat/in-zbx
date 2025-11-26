param ($Metric = $args[0])

$configPath = "C:\Program Files\Zabbix Agent\script\config\1c_config.psd1"
$CONFIG_1C = Import-PowerShellDataFile -Path $configPath

try {
    $Rac = $CONFIG_1C.RacPath
    $cluster = $CONFIG_1C.ClusterId
    $user = $CONFIG_1C.ClusterUser
    $pwd = $CONFIG_1C.ClusterPwd
    $server = $CONFIG_1C.Server

    switch ($Metric) {
        # -------------------------------------------------------
        # Количество рабочих процессов
        # -------------------------------------------------------
        "count" {
            $result = & $Rac process list `
                --cluster=$cluster `
                --cluster-user=$user `
                --cluster-pwd=$pwd `
                $server 2>$null

            if ($LASTEXITCODE -ne 0 -or !$result) {
                Write-Output 0
                break
            }

            $count = ($result | Select-String "^\s*process\s*:").Count
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
