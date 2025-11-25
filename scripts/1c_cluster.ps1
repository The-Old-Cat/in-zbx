param($Metric = $args[0])

try {
    if ($Metric -eq "processes_count") {
        & "C:\Program Files\Zabbix Agent\script\1c_processes.ps1" "count"
    }
    elseif ($Metric -eq "sessions_count") {
        & "C:\Program Files\Zabbix Agent\script\1c_sessions.ps1" "count"
    }
    elseif ($Metric -eq "infobases_count") {
        & "C:\Program Files\Zabbix Agent\script\1c_infobases.ps1" "total_count"
    }
    else {
        0
    }
}
catch {
    0
}