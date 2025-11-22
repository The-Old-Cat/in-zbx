param(
    [string]$command
)

# === UTF-8 для корректного вывода в Zabbix ===
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Convert-ToMB {
    param(
        [long]$bytes
    )
    return ("{0} MB" -f [math]::Round($bytes / 1MB, 2))
}
# === КОНФИГУРАЦИЯ ===
$racPath = "путь к rac.exe"
$clusterId = "UUID кластера"
$clusterUser = "имя пользователя администратора кластера"
$clusterPwd = "пароль администратора кластера"
$server = "localhost:1545" # порт на котором запущен 1C:Enterprise Remote Server

try {
    switch ($command) {

        "session" {
            $sessions = @()
            $ibMap = @{}

            # Получение инфобаз
            $ibOutput = & "$racPath" infobase summary list --cluster=$clusterId --cluster-user=$clusterUser --cluster-pwd=$clusterPwd $server

            foreach ($line in $ibOutput) {
                $line = $line.Trim()

                if ($line -match "^infobase\s*:\s*(.+)$") {
                    $currentIB = $matches[1].Trim()
                    $ibMap[$currentIB] = ""
                }
                elseif ($line -match "^name\s*:\s*(.+)$" -and $currentIB) {
                    $ibMap[$currentIB] = $matches[1].Trim().Trim('"')
                }
            }

            # Получение сессий
            $output = & "$racPath" session list --cluster=$clusterId --cluster-user=$clusterUser --cluster-pwd=$clusterPwd $server
            $currentSession = @{}

            foreach ($line in $output) {
                $line = $line.Trim()

                if ($line -eq "" -and $currentSession.Count -gt 0) {
                    if ($currentSession.session -and $currentSession.infobase) {
                        if ($ibMap.ContainsKey($currentSession.infobase)) {
                            $currentSession.infobase = $ibMap[$currentSession.infobase]
                        }
                        $sessions += $currentSession
                    }
                    $currentSession = @{}
                }
                elseif ($line -match "^([\w-]+)\s*:\s*(.+)$") {
                    $key = $matches[1]
                    $value = $matches[2].Trim()

                    switch ($key) {
                        "session"      { $currentSession.session = $value }
                        "infobase"     { $currentSession.infobase = $value }
                        "user-name"    { $currentSession.user = $value }
                        "host"         { $currentSession.ip = $value }
                        "client-ip"    { $currentSession.client_ip = $value }
                        "memory-current" { $currentSession.memory_current = $value }
                        "memory-5min"    { $currentSession.memory_5min = $value }
                        "memory-total"   { $currentSession.memory_total = $value }
                        "duration-all"   { $currentSession.duration_all = $value }
                        "duration-5min"  { $currentSession.duration_5min = $value }
                        "cpu-total"      { $currentSession.cpu_total = $value }
                        "cpu-5min"       { $currentSession.cpu_5min = $value }
                        "bytes-all"      { $currentSession.bytes_all = $value }
                        "bytes-5min"     { $currentSession.bytes_5min = $value }
                        "calls-all"      { $currentSession.calls_all = $value }
                        "calls-5min"     { $currentSession.calls_5min = $value }
                        default {}
                    }
                }
            }

            # Последний блок
            if ($currentSession.Count -gt 0 -and $currentSession.session) {
                if ($ibMap.ContainsKey($currentSession.infobase)) {
                    $currentSession.infobase = $ibMap[$currentSession.infobase]
                }
                $sessions += $currentSession
            }

            # LLD JSON
            $lld = $sessions | ForEach-Object {
                [PSCustomObject]@{
                    "{#USER}"           = $_.user
                    "{#SESSION}"        = $_.session
                    "{#INFOBASE}"       = $_.infobase
                    "{#HOST}"           = $_.ip
                    "{#CLIENT_IP}"      = $_.client_ip

                    "{#MEMORY_CURRENT}" = if ($_.memory_current) { [math]::Round($_.memory_current/1MB,2) } else { 0 }
                    "{#MEMORY_5MIN}"    = if ($_.memory_5min) { [math]::Round($_.memory_5min/1MB,2) } else { 0 }
                    "{#MEMORY_TOTAL}"   = if ($_.memory_total) { [math]::Round($_.memory_total/1MB,2) } else { 0 }


                    "{#DURATION_ALL}"   = if ($_.duration_all) { [math]::Round([int]$_.duration_all/1000) } else { 0 }
                    "{#DURATION_5MIN}"  = if ($_.duration_5min) { [math]::Round([int]$_.duration_5min/1000) } else { 0 }

                    "{#CPU_TOTAL}"      = if ($_.cpu_total) { [math]::Round([int]$_.cpu_total/1000) } else { 0 }
                    "{#CPU_5MIN}"       = if ($_.cpu_5min) { [math]::Round([int]$_.cpu_5min/1000) } else { 0 }


                    "{#BYTES_ALL}"      = if ($_.bytes_all) { Convert-ToMB $_.bytes_all } else { "0 MB" }
                    "{#BYTES_5MIN}"     = if ($_.bytes_5min) { Convert-ToMB $_.bytes_5min } else { "0 MB" }

                    "{#CALLS_ALL}"      = if ($_.calls_all) { $_.calls_all } else { "0" }
                    "{#CALLS_5MIN}"     = if ($_.calls_5min) { $_.calls_5min } else { "0" }
                }
            }

            $lld | ConvertTo-Json -Compress
        }
        

        default {
            @() | ConvertTo-Json -Compress
        }
    }
}
catch {
    @() | ConvertTo-Json -Compress
}
