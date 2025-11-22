param(
    [string]$command
)

# === UTF-8 для корректного вывода в Zabbix ===
$OutputEncoding = [System.Text.Encoding]::UTF8

# === КОНФИГУРАЦИЯ ===
$racPath = "путь к rac.exe"
$clusterId = "UUID кластера"
$clusterUser = "имя пользователя администратора кластера"
$clusterPwd = "пароль администратора кластера"
$server = "localhost:1545" # порт на котором запущен 1C:Enterprise Remote Server

# Log file path for debugging
$logFile = "C:\Program Files\Zabbix Agent\script\1c_rac_stats.log"

try {
    # Clear log file
    "" | Out-File -FilePath $logFile -Encoding utf8

    switch ($command) {

        "infobase" {
            "Executing command: infobase" | Out-File -FilePath $logFile -Append -Encoding utf8

            $output = & $racPath infobase summary list `
                --cluster=$clusterId `
                --cluster-user=$clusterUser `
                --cluster-pwd=$clusterPwd `
                $server 2>&1 | Out-String

            "Raw output:`n$output" | Out-File -FilePath $logFile -Append -Encoding utf8

            $infobases = @()
            $current = $null

            foreach ($line in ($output -split "`n")) {
                if ($line -match "infobase\s*:\s*(.+)") {
                    if ($current) { $infobases += $current }
                    $current = @{
                        infobase = $matches[1].Trim()
                        name     = ""
                        descr    = ""
                    }
                }
                elseif ($line -match "name\s*:\s*(.+)") {
                    $current.name = $matches[1].Trim().Trim('"')
                }
                elseif ($line -match "descr\s*:\s*(.+)") {
                    $current.descr = $matches[1].Trim().Trim('"')
                }
            }

            if ($current) { $infobases += $current }

            $json = $infobases | ConvertTo-Json -Compress
            Write-Output $json
            "JSON:`n$json" | Out-File -FilePath $logFile -Append -Encoding utf8
        }
        
        default {
            "Unknown command: $command" | Out-File $logFile -Append -Encoding utf8
            Write-Output "Unknown command"
            exit 1
        }
    }

}
catch {
    $msg = "Error: $($_.Exception.Message)"
    $msg | Out-File -FilePath $logFile -Append -Encoding utf8
    Write-Output $msg
    exit 1
}