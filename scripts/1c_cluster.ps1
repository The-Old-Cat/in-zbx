# Кластер 1С - рабочие процессы, блокировки

. "C:\Program Files\Zabbix Agent\script\1c_cache.ps1"

$Metric = $args[0]

function Get-LocksData {
    $raw = Invoke-RacCommand "lock" @("list")
    $locks = @()
    $current = @{}
    
    foreach ($line in $raw) {
        $line = $line.Trim()
        if ($line -eq "" -and $current.Count -gt 0) {
            if ($current.connection) {
                $locks += [PSCustomObject]@{
                    connection = $current.connection
                    session = $current.session
                    infobase = $current.infobase
                }
            }
            $current = @{}
        }
        elseif ($line -match "^([\w-]+)\s*:\s*(.+)$") {
            $current[$matches[1]] = $matches[2].Trim()
        }
    }
    return $locks
}

try {
    switch ($Metric) {
        "processes_count" {
            $processes = Get-CachedData "processes" { 
                . "C:\Program Files\Zabbix Agent\script\1c_processes.ps1"
                Get-ProcessesData
            }
            Write-Output $processes.Count
        }
        "locks_count" {
            $locks = Get-CachedData "locks" { Get-LocksData }
            Write-Output $locks.Count
        }
        "sessions_count" {
            $sessions = Get-CachedData "sessions" { 
                . "C:\Program Files\Zabbix Agent\script\1c_sessions.ps1"
                Get-SessionsData
            }
            Write-Output $sessions.Count
        }
        "infobases_count" {
            $infobases = Get-CachedData "infobases" { 
                . "C:\Program Files\Zabbix Agent\script\1c_infobases.ps1"
                Get-InfobasesData
            }
            Write-Output $infobases.Count
        }
        "background_jobs_count" {
            $jobs = Get-CachedData "background_jobs" { 
                . "C:\Program Files\Zabbix Agent\script\1c_infobases.ps1"
                Get-BackgroundJobs
            }
            Write-Output $jobs.Count
        }
        default { Write-Output 0 }
    }
}
catch {
    Write-Output 0
}