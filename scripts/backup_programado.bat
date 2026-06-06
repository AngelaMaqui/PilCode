@echo off
REM Backup programado PIL Andina - Programar en el Programador de tareas de Windows
set FECHA=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set FECHA=%FECHA: =0%
set DESTINO=%~dp0..\backups\respaldo_auto_%FECHA%.sql
mysqldump -u root pil_andina > "%DESTINO%"
echo Respaldo creado: %DESTINO%
