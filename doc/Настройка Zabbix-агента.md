# Конфигурация Zabbix-agent
  
> [!note]
> После установки клиента Zabbix настраиваем его конфигурационный файл
>
> `C:\Program Files\Zabbix Agent\zabbix_agentd.conf` - Windows
>
> `/etc/zabbix/zabbix_agentd.conf` - Linux
>
> путь может отличатся, если изменили при установке

В секции `Server` прописываем IP-адреса с которых будут приходить запросы:
IP-localhost необходим для тестовых запросов через `zabbix_get` и IP сервера Zabbix

```conf
# Mandatory: yes, if StartAgents is not explicitly set to 0
# Default:
# Server=

#======== Server=127.0.0.1,IP_вашего_Zabbix_сервера ==========
Server=

```

В секции `ServerActive` прописываем IP сервера Zabbix

```conf
# Mandatory: no
# Default:
# ServerActive=
#======== Server=IP_вашего_Zabbix_сервера ==========

ServerActive=IP_of_your_Zabbix_Server
```

В секции `Hostname` указываем имя хоста на котором запущен клиент
Это же имя указывать при создании узла сети в Zabbix

```conf
# Mandatory: no

# Default:

# Hostname=
# ============= имя хоста на котором запущен клиент==========

Hostname=Zabbix_client_hostname
```

В секции `Timeout` указываем время ожидания выполнения скриптов-запросов

```conf
# Mandatory: no
# Range: 1-30
# Default:
# Timeout=3
# ============= Время ожидания выполнения скриптов-запросов  

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
