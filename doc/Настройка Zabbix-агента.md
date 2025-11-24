# Конфигурация Zabbix-agent для мониторинга 1С:Предприятие

> [!note]
> После установки клиента Zabbix, настраиваем его конфигурационный файл
>
> `C:\Program Files\Zabbix Agent\zabbix_agentd.conf` - Windows
>
> `/etc/zabbix/zabbix_agentd.conf` - Linux
>
> путь может отличатся, если изменили при установке

## Основные настройки

В секции `Server` прописываем IP-адреса с которых будут приходить запросы:
IP-localhost необходим для тестовых запросов через `zabbix_get` и IP сервера Zabbix

```conf
# Mandatory: yes, if StartAgents is not explicitly set to 0
# Default:
# Server=

#======== Server=127.0.0.1,IP_вашего_Zabbix_сервера ==========
Server=127.0.0.1,111.111.111.111
```

В секции `ServerActive` прописываем IP сервера Zabbix для активных проверок

```conf
# Mandatory: no
# Default:
# ServerActive=
#======== Server=IP_вашего_Zabbix_сервера ==========

ServerActive=111.111.111.111
```

В секции `Hostname` указываем имя хоста на котором запущен клиент
Это же имя указывать при создании узла сети в Zabbix

```conf
# Mandatory: no
# Default:
# Hostname=
# ============= имя хоста на котором запущен клиент==========

Hostname=Host-name
```

В секции `Timeout` указываем время ожидания выполнения скриптов-запросов

```conf
# Mandatory: no
# Range: 1-30
# Default:
# Timeout=3
# ============= Время ожидания выполнения скриптов-запросов  
# Ограничиваем количество одновременно выполняемых проверок
# Mandatory: no
# Range: 1-100
# Default:
# StartAgents=3

StartAgents=5
Timeout=30
```

В секции `UnsafeUserParameters` разрешаем использование пользовательских параметров (UserParameters)
с произвольными командами в Zabbix Agent

```conf
# Mandatory: no
# Range: 0-1
# Default:
# ========== разрешаем использование пользовательских параметров (UserParameters) ====
# ========== с произвольными командами в Zabbix Agent ================================

UnsafeUserParameters=1
```

## Настройки безопасности

В секции `AllowKey` разрешаем выполнение удаленных команд для мониторинга

```conf
# Mandatory: no
# ========== разрешаем выполнение системных команд для сбора метрик ==========

AllowKey=system.run[*]
```

В секции `LogRemoteCommands` включаем логирование выполняемых команд для отладки

```conf
# Mandatory: no
# Default:
# LogRemoteCommands=0
# ========== включаем логирование команд для отслеживания проблем ==========

LogRemoteCommands=1
```

## Пользовательские параметры для мониторинга 1С

> [!important]
> Для работы мониторинга 1С необходимо разместить PowerShell скрипты в директории:
> `C:\Program Files\Zabbix Agent\script\`

### Мониторинг процессов 1С

```conf
# ========== Обнаружение и мониторинг процессов 1С ==========

# Автоматическое обнаружение всех процессов 1С
UserParameter=1c.processes.discovery,powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_processes.ps1" discovery

# Общее количество процессов 1С
UserParameter=1c.processes.count,powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_processes.ps1" count

# Детальная информация о конкретном процессе
UserParameter=1c.processes.detail[*],powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c.processes.ps1" "$1" "$2"
```

### Мониторинг сессий 1С

```conf
# ========== Мониторинг пользовательских сессий 1С ==========

# Обнаружение всех активных сессий
UserParameter=1c.sessions.discovery,powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_sessions.ps1" discovery

# Общее количество сессий
UserParameter=1c.sessions.count,powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_sessions.ps1" count

# Детальная информация о сессии
UserParameter=1c.sessions.detail[*],powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_sessions.ps1" "$1" "$2"

# Количество сессий по информационным базам
UserParameter=1c.sessions.by_infobase[*],powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_sessions.ps1" count_by_infobase "$1"
```

### Мониторинг информационных баз

```conf
# ========== Мониторинг информационных баз 1С ==========

# Обнаружение всех информационных баз
UserParameter=1c.infobases.discovery,powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_infobases.ps1" discovery

# Общее количество информационных баз
UserParameter=1c.infobases.count,powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_infobases.ps1" total_count

# Количество сессий по информационной базе
UserParameter=1c.infobases.sessions[*],powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_infobases.ps1" sessions_count "$1"

# Количество фоновых заданий
UserParameter=1c.infobases.jobs[*],powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_infobases.ps1" background_jobs_count "$1"

# Статус запрета сессий и заданий
UserParameter=1c.infobases.deny.sessions[*],powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_infobases.ps1" sessions_deny "$1"
UserParameter=1c.infobases.deny.jobs[*],powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_infobases.ps1" jobs_deny "$1"
```

### Мониторинг кластера 1С

```conf
# ========== Общий мониторинг кластера 1С ==========

# Ключевые метрики кластера
UserParameter=1c.cluster.processes.count,powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_cluster.ps1" processes_count
UserParameter=1c.cluster.sessions.count,powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_cluster.ps1" sessions_count
UserParameter=1c.cluster.infobases.count,powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_cluster.ps1" infobases_count
UserParameter=1c.cluster.locks.count,powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_cluster.ps1" locks_count
UserParameter=1c.cluster.jobs.count,powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent\script\1c_cluster.ps1" background_jobs_count
```

> [!tip]
> После изменения конфигурации необходимо перезапустить службу Zabbix Agent:
>
> - Windows: `Restart-Service "Zabbix Agent"`
> - Linux: `systemctl restart zabbix-agent`
