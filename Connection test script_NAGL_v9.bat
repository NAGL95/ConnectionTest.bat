@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Путь к рабочему столу
set "desktop=%USERPROFILE%\Desktop"

:: Поиск следующего номера
set "prefix=ConnectionTest"
set /a num=1
:find_next
set "filename=%prefix%_0%num%_%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%.txt"
set "outfile=%desktop%\%filename%"
set "tempstatus=%desktop%\_temp_status.txt"
if exist "%outfile%" (
    set /a num+=1
    goto find_next
)

if exist "%tempstatus%" del "%tempstatus%"

:: Сбор имени хоста и локального IP
for /f "delims=" %%i in ('hostname') do set "hostname=%%i"
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /C:"IPv4"') do set "localip=%%i"
set "localip=%localip: =%"

:: Заголовок отчёта
echo РЕЗУЛЬТАТЫ ТЕСТОВ > "%tempstatus%"
echo ================== >> "%tempstatus%"
echo Хост: %hostname% >> "%tempstatus%"
echo Локальный IP: %localip% >> "%tempstatus%"
echo. >> "%tempstatus%"

:: Основной файл
echo ==== IPConfig /all ==== >> "%outfile%"
ipconfig /all >> "%outfile%" 2>&1
if !ERRORLEVEL! EQU 0 (
    echo IPConfig — ОК >> "%tempstatus%"
) else (
    echo IPConfig — ОШИБКА >> "%tempstatus%"
)

:: Сетевые тесты
set domains=google.com modimio.ru
set /a current=1
set /a total=7

for %%d in (%domains%) do (
    set /a current+=1
    set /a percent=100 * !current! / !total!
    echo [!percent!%%] Ping + Tracert %%d...

    echo ===== Ping %%d ===== >> "%outfile%"
    ping -n 4 %%d >> "%outfile%" 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo Ping %%d — ОК >> "%tempstatus%"
    ) else (
        echo Ping %%d — НЕТ ОТВЕТА >> "%tempstatus%"
    )

    echo ===== Tracert %%d ===== >> "%outfile%"
    tracert -d %%d >> "%outfile%" 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo Tracert %%d — ОК >> "%tempstatus%"
    ) else (
        echo Tracert %%d — ОШИБКА >> "%tempstatus%"
    )

    echo. >> "%outfile%"
)

:: nslookup
set /a current+=1
set /a percent=100 * !current! / !total!
echo [!percent!%%] nslookup modimio.ru...

echo ===== nslookup modimio.ru ===== >> "%outfile%"
nslookup modimio.ru >> "%outfile%" 2>&1
if !ERRORLEVEL! EQU 0 (
    echo nslookup modimio.ru — ОК >> "%tempstatus%"
) else (
    echo nslookup modimio.ru — ОШИБКА >> "%tempstatus%"
)

:: curl
set /a current+=1
set /a percent=100 * !current! / !total!
echo [!percent!%%] curl modimio.ru...

where curl.exe >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo curl — НЕ НАЙДЕН >> "%tempstatus%"
    echo curl не найден, пропущено >> "%outfile%"
) else (
    echo ===== curl -I modimio.ru ===== >> "%outfile%"
    curl.exe -I modimio.ru >> "%outfile%" 2>&1
    if !ERRORLEVEL! EQU 0 (
        echo curl modimio.ru — ОК >> "%tempstatus%"
    ) else (
        echo curl modimio.ru — ОШИБКА >> "%tempstatus%"
    )
)

:: Остальная информация
echo ===== Display DNS ===== >> "%outfile%"
ipconfig /displaydns >> "%outfile%" 2>&1
if !ERRORLEVEL! EQU 0 (
    echo DisplayDNS — ОК >> "%tempstatus%"
) else (
    echo DisplayDNS — ОШИБКА >> "%tempstatus%"
)

echo ===== Route Print ===== >> "%outfile%"
route print >> "%outfile%" 2>&1
if !ERRORLEVEL! EQU 0 (
    echo Route Print — ОК >> "%tempstatus%"
) else (
    echo Route Print — ОШИБКА >> "%tempstatus%"
)

:: Объединение итогов и логов
copy "%tempstatus%" + "%outfile%" "%outfile%.final" >nul
del "%outfile%"
del "%tempstatus%"
ren "%outfile%.final" "%filename%"

:: Финал
echo.
echo Готово! Результаты сохранены в:
echo %outfile%
start "" explorer.exe /select,"%outfile%"
start "" "%outfile%"
pause
