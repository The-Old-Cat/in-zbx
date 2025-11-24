# Общие настройки и функции кэширования
$global:RAC_CONFIG = @{
    RacPath = "Путь\к\rac.exe"
    ClusterId = "Cluster-UUID"
    ClusterUser = "ClusterAdminUser"
    ClusterPwd = "ClusterAdminUserPassWord"
    Server = "localhost:1545"
    CacheDir = "C:\Program Files\Zabbix Agent\script\cache"
    CacheTTL = 30  # секунд
}

# Создаем директорию кэша
if (!(Test-Path $RAC_CONFIG.CacheDir)) {
    New-Item -ItemType Directory -Path $RAC_CONFIG.CacheDir -Force
}

function Get-CachedData {
    param($CacheKey, $Command)
    
    $cacheFile = Join-Path $RAC_CONFIG.CacheDir "$CacheKey.json"
    $lockFile = "$cacheFile.lock"
    
    # Проверяем актуальность кэша
    if (Test-Path $cacheFile) {
        $cacheAge = (Get-Date) - (Get-Item $cacheFile).LastWriteTime
        if ($cacheAge.TotalSeconds -lt $RAC_CONFIG.CacheTTL) {
            try {
                $content = Get-Content $cacheFile -Raw -Encoding UTF8
                return $content | ConvertFrom-Json
            } catch {
                # Если файл поврежден, пересоздаем кэш
                Remove-Item $cacheFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    # Блокировка для избежания параллельных вызовов
    if (Test-Path $lockFile) {
        Start-Sleep -Seconds 2
        if (Test-Path $cacheFile) {
            try {
                $content = Get-Content $cacheFile -Raw -Encoding UTF8
                return $content | ConvertFrom-Json
            } catch {
                Remove-Item $cacheFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    try {
        New-Item $lockFile -Force | Out-Null
        $data = & $Command
        $data | ConvertTo-Json -Depth 10 | Out-File $cacheFile -Encoding UTF8
        return $data
    }
    finally {
        Remove-Item $lockFile -ErrorAction SilentlyContinue
    }
}

function Invoke-RacCommand {
    param($RacCommand, $Arguments = @())
    
    $params = @(
        $RacCommand
        "--cluster", $RAC_CONFIG.ClusterId
        "--cluster-user", $RAC_CONFIG.ClusterUser  
        "--cluster-pwd", $RAC_CONFIG.ClusterPwd
        $RAC_CONFIG.Server
    ) + $Arguments
    
    $result = & $RAC_CONFIG.RacPath @params 2>$null
    return $result
}