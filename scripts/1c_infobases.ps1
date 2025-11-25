param($Metric = $args[0])

try {
    $RacPath = "C:\Program Files\1cv8\8.3.27.1786\bin\rac.exe"
    
    if ($Metric -eq "total_count") {
        $result = & $RacPath infobase summary list --cluster=c7313ba1-5875-4498-8184-4a830f12d77f --cluster-user=new_1cPin --cluster-pwd=!Admin1c!159753 localhost:1545 2>$null
        
        # Безопасная проверка на null
        if ($LASTEXITCODE -eq 0 -and $result -ne $null) {
            $count = 0
            foreach ($line in $result) {
                if ($line -ne $null -and $line -match "^\s*infobase\s*:") {
                    $count++
                }
            }
            Write-Output $count
        } else {
            Write-Output 0
        }
    }
    elseif ($Metric -eq "discovery") {
        # Пока возвращаем пустой discovery
        Write-Output '{"data":[]}'
    }
    else {
        Write-Output 0
    }
}
catch {
    Write-Output 0
}