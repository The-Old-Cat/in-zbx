# Инфобазы 1С - размер, сессии, фоновые задания

. "C:\Program Files\Zabbix Agent\script\1c_cache.ps1"

$Metric = $args[0]
$InfobaseName = $args[1]  # Теперь принимаем имя базы вместо UUID

function Get-InfobasesData {
    $raw = Invoke-RacCommand "infobase" @("summary", "list")
    $infobases = @()
    $current = @{}
    
    foreach ($line in $raw) {
        $line = $line.Trim()
        if ($line -eq "" -and $current.Count -gt 0) {
            if ($current.infobase -and $current.name) {
                # Исправляем кодировку имени базы
                $name = $current.name.Trim().Trim('"')
                $name = [System.Text.Encoding]::GetEncoding(1251).GetString(
                    [System.Text.Encoding]::UTF8.GetBytes($name)
                )
                
                $infobases += [PSCustomObject]@{
                    infobase = $current.infobase
                    name = $name  # Чистое имя с исправленной кодировкой
                    descr = $current.descr
                    dbms = $current.dbms
                    db_server = $current.'db-server'
                    db_name = $current.'db-name'
                    sessions_deny = $current.'sessions-deny'
                    scheduled_jobs_deny = $current.'scheduled-jobs-deny'
                }
            }
            $current = @{}
        }
        elseif ($line -match "^([\w-]+)\s*:\s*(.+)$") {
            $current[$matches[1]] = $matches[2].Trim()
        }
    }
    return $infobases
}

function Get-BackgroundJobs {
    $raw = Invoke-RacCommand "backgroundjob" @("list")
    $jobs = @()
    $current = @{}
    
    foreach ($line in $raw) {
        $line = $line.Trim()
        if ($line -eq "" -and $current.Count -gt 0) {
            if ($current.job) {
                $jobs += [PSCustomObject]@{
                    job = $current.job
                    infobase = $current.infobase
                    name = $current.name
                    state = $current.state
                }
            }
            $current = @{}
        }
        elseif ($line -match "^([\w-]+)\s*:\s*(.+)$") {
            $current[$matches[1]] = $matches[2].Trim()
        }
    }
    return $jobs
}

try {
    if ($Metric -eq "discovery") {
        $infobases = Get-CachedData "infobases" { Get-InfobasesData }
        $lld = $infobases | ForEach-Object {
            @{
                "{#IBNAME}" = $_.name  # Только имя базы
                "{#IBUUID}" = $_.infobase  # UUID для обратной совместимости
            }
        }
        $json = @{data = $lld} | ConvertTo-Json -Compress -Depth 5
        Write-Output $json
    }
    elseif ($Metric -eq "sessions_count" -and $InfobaseName) {
        $sessions = Get-CachedData "sessions" { 
            . "C:\Program Files\Zabbix Agent\script\1c_sessions.ps1"
            Get-SessionsData
        }
        Write-Output ($sessions | Where-Object infobase -eq $InfobaseName).Count
    }
    elseif ($Metric -eq "background_jobs_count" -and $InfobaseName) {
        $jobs = Get-CachedData "background_jobs" { Get-BackgroundJobs }
        # Нужно получить UUID по имени для поиска в jobs
        $infobases = Get-CachedData "infobases" { Get-InfobasesData }
        $ib = $infobases | Where-Object name -eq $InfobaseName | Select-Object -First 1
        if ($ib) {
            Write-Output ($jobs | Where-Object infobase -eq $ib.infobase).Count
        } else {
            Write-Output 0
        }
    }
    elseif ($Metric -eq "sessions_deny" -and $InfobaseName) {
        $infobases = Get-CachedData "infobases" { Get-InfobasesData }
        $ib = $infobases | Where-Object name -eq $InfobaseName | Select-Object -First 1
        if ($ib -and $ib.sessions_deny -eq 'yes') { Write-Output 1 } else { Write-Output 0 }
    }
    elseif ($Metric -eq "jobs_deny" -and $InfobaseName) {
        $infobases = Get-CachedData "infobases" { Get-InfobasesData }
        $ib = $infobases | Where-Object name -eq $InfobaseName | Select-Object -First 1
        if ($ib -and $ib.scheduled_jobs_deny -eq 'yes') { Write-Output 1 } else { Write-Output 0 }
    }
    elseif ($Metric -eq "total_count") {
        $infobases = Get-CachedData "infobases" { Get-InfobasesData }
        Write-Output $infobases.Count
    }
    else {
        Write-Output 0
    }
}
catch {
    Write-Output 0
}