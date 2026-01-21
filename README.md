# in-zbx

Мониторинг 1С:Предприятие через Zabbix с использованием RAC (Remote Administration Console).

## 📚 Документация

[/doc](doc)

- [Настройка Zabbix-агента](doc/Настройка%20Zabbix-агента.md) — конфигурация агента для мониторинга 1С
- [Используемые скрипты](doc/Используемые%20скрипты.md) — описание PowerShell скриптов для сбора метрик
- [1С RAC](doc/1С%20RAC.md) — справочник по утилите RAC (Remote Administrative Client)

## ⚙️ Конфигурация

[/conf](conf)

- [zabbix_agentd.conf](conf/zabbix_agentd.conf) — основной конфигурационный файл агента
- [1c_extended.conf](conf/zabbix_agentd.conf.d/1c_extended.conf) — расширенные параметры для мониторинга 1С

## 📜 Скрипты

[/scripts](scripts)

- [1c_sessions.ps1](scripts/1c_sessions.ps1) — мониторинг сессий 1С
- [1c_processes.ps1](scripts/1c_processes.ps1) — мониторинг рабочих процессов
- [1c_processes_lld.ps1](scripts/1c_processes_lld.ps1) — LLD обнаружение процессов
- [1c_processes_detail.ps1](scripts/1c_processes_detail.ps1) — детальные метрики процессов
- [1c_infobases.ps1](scripts/1c_infobases.ps1) — мониторинг информационных баз
- [1c_infobases_lld.ps1](scripts/1c_infobases_lld.ps1) — LLD обнаружение информационных баз
- [1c_infobases_list.ps1](scripts/1c_infobases_list.ps1) — список информационных баз
- [1c_cache.ps1](scripts/1c_cache.ps1) — кэширование данных
- [1c_tech_log_monitor_1c.ps1](scripts/1c_tech_log_monitor_1c.ps1) — мониторинг технологического журнала

### Конфигурация скриптов

[/scripts/config](scripts/config/)

- [exemple-1c_config.psd1](scripts/config/exemple-1c_config.psd1) — пример файла конфигурации

## 📋 Шаблоны Zabbix

[/Templates](Templates/)

- [zbx_1c_templates.yaml](Templates/zbx_1c_templates.yaml) — базовый шаблон
- [zbx_1c_templates1.0.1.yaml](Templates/zbx_1c_templates1.0.1.yaml) — версия 1.0.1
- [zbx_1c_templates1.0.2.yaml](Templates/zbx_1c_templates1.0.2.yaml) — версия 1.0.2
- [zbx_1c_templates1.0.3.yaml](Templates/zbx_1c_templates1.0.3.yaml) — версия 1.0.3

## 🚀 Быстрый старт

1. Установите Zabbix Agent на сервер 1С
2. Скопируйте скрипты из `/scripts` в `C:\Program Files\Zabbix Agent\script\`
3. Создайте файл конфигурации `1c_config.psd1` на основе примера
4. Настройте `zabbix_agentd.conf` согласно [инструкции](doc/Настройка%20Zabbix-агента.md)
5. Импортируйте шаблон в Zabbix Server
6. Привяжите шаблон к хосту

## 📄 Лицензия

[MIT License](LICENSE)
