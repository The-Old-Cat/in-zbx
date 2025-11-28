# Обёртка для преобразования JSON в текстовый список
$json = & "C:\Program Files\Zabbix Agent\script\1c_infobases_lld.ps1" "discovery" | ConvertFrom-Json

foreach ($item in $json.data) {
    Write-Output $item.'{#IBNAME}'
}