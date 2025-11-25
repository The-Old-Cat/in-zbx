# in-zbx

[/doc](doc)

- [Настройка Zabbix-агента](doc/Настройка%20Zabbix-агента.md)
- [1C RAC](doc/1С%20RAC.md)
  
[/conf](conf)

- [zabbix_agentd.conf](conf/zabbix_agentd.conf)

[/scripts](scripts)

- [1c_sessions.ps1](scripts/1c_sessions.ps1)
- [1c_processes.ps1](scripts/1c_processes.ps1)
- [1c_infobases.ps1](scripts/1c_infobases.ps1)

  [/config](scripts/config/)

  - [1c_config.psd1](scripts/config/)

```powershell
#1c_config.psd1
      # Конфигурация подключения к 1С кластеру
@{
    RacPath     = "Путь\к\rac.exe"
    ClusterId   = "UUID Кластера"
    ClusterUser = "Администратор кластера"
    ClusterPwd  = "Пароль администратора"
    Server      = "localhost:1545"
    CacheDir    = "C:\Program Files\Zabbix Agent\script\cache"
}
```
