@echo off
chcp 65001 >nul
setlocal EnableExtensions
cd /d "%~dp0"

rem Все инструменты берутся из папки проекта (tools), а не из системного PATH.
rem PATH меняется только внутри этого окна (setlocal выше).
set "TOOLS=%~dp0tools"
set "DENO_INSTALL=%TOOLS%\deno"
set "PATH=%TOOLS%;%DENO_INSTALL%\bin;%TOOLS%\ffmpeg\bin;%PATH%"

set "LINKS=downloads\links.txt"

title yt-dlp menu

if not exist "%TOOLS%\yt-dlp.exe" goto need_setup
if not exist "%TOOLS%\ffmpeg\bin\ffmpeg.exe" goto need_setup
if not exist "%DENO_INSTALL%\bin\deno.exe" goto need_setup
goto main

:need_setup
echo Не найдены нужные инструменты в папке tools
echo Сначала запусти setup.bat
echo.
pause
exit /b 1

:main
cls
echo ==========================================
echo              YT-DLP MENU
echo ==========================================
echo.
echo  1 ^) Лучшее видео + аудио (макс. качество)
echo  2 ^) Лучшее видео + аудио в MP4
echo  3 ^) Только аудио MP3
echo  4 ^) Только превью
echo  5 ^) Показать обычные субтитры
echo  6 ^) Показать автоматические субтитры
echo  7 ^) Скачать обычные субтитры
echo  8 ^) Скачать автоматические субтитры
echo  9 ^) Видео + обычные субтитры
echo 10 ^) Видео + автоматические субтитры
echo 11 ^) Показать доступные форматы видео/аудио
echo 12 ^) Скачать всё из links.txt
echo 13 ^) Открыть папку загрузки
echo  0 ^) Выход
echo.
set /p MODE=Выбери пункт: 

if "%MODE%"=="1" goto mode_best
if "%MODE%"=="2" goto mode_mp4
if "%MODE%"=="3" goto mode_mp3
if "%MODE%"=="4" goto mode_thumb
if "%MODE%"=="5" goto mode_list_subs
if "%MODE%"=="6" goto mode_list_auto_subs
if "%MODE%"=="7" goto mode_subs
if "%MODE%"=="8" goto mode_auto_subs
if "%MODE%"=="9" goto mode_video_subs
if "%MODE%"=="10" goto mode_video_auto_subs
if "%MODE%"=="11" goto mode_formats
if "%MODE%"=="12" goto batch_menu
if "%MODE%"=="13" goto open_downloads
if "%MODE%"=="0" exit /b

echo.
echo Неверный пункт
pause
goto main

:get_url
echo.
set "URL="
set /p URL=Вставь ссылку: 
if not defined URL (
    echo Ссылка пустая
    pause
    goto main
)
exit /b

:ensure_dirs
if not exist "downloads" mkdir "downloads"
if not exist "downloads\video" mkdir "downloads\video"
if not exist "downloads\audio" mkdir "downloads\audio"
if not exist "downloads\thumbs" mkdir "downloads\thumbs"
if not exist "downloads\subs" mkdir "downloads\subs"
exit /b

:choose_sub_langs
cls
echo ===============================
echo      ВЫБОР ЯЗЫКОВ СУБТИТРОВ
echo ===============================
echo.
echo 1^) Японский            ^(ja^)
echo 2^) Английский          ^(en^)
echo 3^) Русский             ^(ru^)
echo 4^) Японский + Английский       ^(ja,en^)
echo 5^) Японский + Русский          ^(ja,ru^)
echo 6^) Английский + Русский        ^(en,ru^)
echo 7^) Японский + Английский + Русский  ^(ja,en,ru^)
echo 8^) Ввести коды вручную
echo.
set "SUBLANGS="
set /p SUBCHOICE=Выбери вариант: 

if "%SUBCHOICE%"=="1" set "SUBLANGS=ja"
if "%SUBCHOICE%"=="2" set "SUBLANGS=en"
if "%SUBCHOICE%"=="3" set "SUBLANGS=ru"
if "%SUBCHOICE%"=="4" set "SUBLANGS=ja,en"
if "%SUBCHOICE%"=="5" set "SUBLANGS=ja,ru"
if "%SUBCHOICE%"=="6" set "SUBLANGS=en,ru"
if "%SUBCHOICE%"=="7" set "SUBLANGS=ja,en,ru"

if "%SUBCHOICE%"=="8" (
    echo.
    echo Примеры: ja  или  ja,en  или  ru
    set /p SUBLANGS=Введи коды языков: 
)

if not defined SUBLANGS (
    echo.
    echo Неверный выбор
    pause
    goto main
)

set "SUBLANGS=%SUBLANGS%,-live_chat"
exit /b

:choose_video_container
cls
echo ===============================
echo      ФОРМАТ ВИДЕО
echo ===============================
echo.
echo 1^) MP4
echo 2^) MKV
echo 3^) WEBM
echo 4^) Как есть ^(без принудительного контейнера^)
echo.
set "VIDFMT="
set /p VIDCHOICE=Выбери формат: 

if "%VIDCHOICE%"=="1" set "VIDFMT=mp4"
if "%VIDCHOICE%"=="2" set "VIDFMT=mkv"
if "%VIDCHOICE%"=="3" set "VIDFMT=webm"
if "%VIDCHOICE%"=="4" set "VIDFMT="

if not defined VIDCHOICE (
    echo.
    echo Неверный выбор
    pause
    goto main
)
exit /b

:choose_audio_format
cls
echo ===============================
echo      ФОРМАТ АУДИО
echo ===============================
echo.
echo 1^) MP3
echo 2^) M4A
echo 3^) WAV
echo 4^) FLAC
echo 5^) OPUS
echo 6^) Как есть ^(без перекодирования^)
echo.
set "AUDFMT="
set /p AUDCHOICE=Выбери формат: 

if "%AUDCHOICE%"=="1" set "AUDFMT=mp3"
if "%AUDCHOICE%"=="2" set "AUDFMT=m4a"
if "%AUDCHOICE%"=="3" set "AUDFMT=wav"
if "%AUDCHOICE%"=="4" set "AUDFMT=flac"
if "%AUDCHOICE%"=="5" set "AUDFMT=opus"
if "%AUDCHOICE%"=="6" set "AUDFMT="

if not defined AUDCHOICE (
    echo.
    echo Неверный выбор
    pause
    goto main
)
exit /b

:choose_sub_format
cls
echo ===============================
echo      ФОРМАТ СУБТИТРОВ
echo ===============================
echo.
echo 1^) SRT
echo 2^) VTT
echo 3^) TTML
echo 4^) Best ^(что лучше доступно^)
echo.
set "SUBFMT="
set /p SUBFCHOICE=Выбери формат: 

if "%SUBFCHOICE%"=="1" set "SUBFMT=srt"
if "%SUBFCHOICE%"=="2" set "SUBFMT=vtt"
if "%SUBFCHOICE%"=="3" set "SUBFMT=ttml"
if "%SUBFCHOICE%"=="4" set "SUBFMT=best"

if not defined SUBFMT (
    echo.
    echo Неверный выбор
    pause
    goto main
)
exit /b

:choose_thumb_format
cls
echo ===============================
echo      ФОРМАТ ПРЕВЬЮ
echo ===============================
echo.
echo 1^) JPG
echo 2^) PNG
echo 3^) WEBP
echo 4^) Как есть ^(без конвертации^)
echo.
set "THUMBFMT="
set /p THUMBCHOICE=Выбери формат: 

if "%THUMBCHOICE%"=="1" set "THUMBFMT=jpg"
if "%THUMBCHOICE%"=="2" set "THUMBFMT=png"
if "%THUMBCHOICE%"=="3" set "THUMBFMT=webp"
if "%THUMBCHOICE%"=="4" set "THUMBFMT="

if not defined THUMBCHOICE (
    echo.
    echo Неверный выбор
    pause
    goto main
)
exit /b

:mode_best
call :ensure_dirs
call :get_url
cls
echo Скачивание: лучшее доступное качество
echo.
yt-dlp.exe ^
--newline ^
--ignore-errors ^
--add-metadata ^
-o "downloads\video\%%(title)s [%%(id)s].%%(ext)s" ^
"%URL%"
echo.
pause
goto main

:mode_mp4
call :ensure_dirs
call :get_url
call :choose_video_container
cls
echo Скачивание: лучшее видео/аудио
if defined VIDFMT echo Контейнер: %VIDFMT%
if not defined VIDFMT echo Контейнер: как есть
echo.

if defined VIDFMT (
    yt-dlp.exe ^
    --newline ^
    --ignore-errors ^
    -f "bestvideo+bestaudio/best" ^
    --merge-output-format %VIDFMT% ^
    --add-metadata ^
    -o "downloads\video\%%(title)s [%%(id)s].%%(ext)s" ^
    "%URL%"
) else (
    yt-dlp.exe ^
    --newline ^
    --ignore-errors ^
    -f "bestvideo+bestaudio/best" ^
    --add-metadata ^
    -o "downloads\video\%%(title)s [%%(id)s].%%(ext)s" ^
    "%URL%"
)

echo.
pause
goto main

:mode_mp3
call :ensure_dirs
call :get_url
call :choose_audio_format
cls
echo Скачивание: аудио
if defined AUDFMT echo Формат: %AUDFMT%
if not defined AUDFMT echo Формат: как есть
echo.

if defined AUDFMT (
    yt-dlp.exe ^
    --newline ^
    --ignore-errors ^
    -x ^
    --audio-format %AUDFMT% ^
    --audio-quality 0 ^
    --add-metadata ^
    --embed-thumbnail ^
    -o "downloads\audio\%%(title)s [%%(id)s].%%(ext)s" ^
    "%URL%"
) else (
    yt-dlp.exe ^
    --newline ^
    --ignore-errors ^
    -f "bestaudio/best" ^
    --add-metadata ^
    -o "downloads\audio\%%(title)s [%%(id)s].%%(ext)s" ^
    "%URL%"
)

echo.
pause
goto main

:mode_thumb
call :ensure_dirs
call :get_url
call :choose_thumb_format
cls
echo Скачивание: только превью
if defined THUMBFMT echo Формат: %THUMBFMT%
if not defined THUMBFMT echo Формат: как есть
echo.

if defined THUMBFMT (
    yt-dlp.exe ^
    --newline ^
    --ignore-errors ^
    --skip-download ^
    --write-thumbnail ^
    --convert-thumbnails %THUMBFMT% ^
    -o "downloads\thumbs\%%(title)s [%%(id)s].%%(ext)s" ^
    "%URL%"
) else (
    yt-dlp.exe ^
    --newline ^
    --ignore-errors ^
    --skip-download ^
    --write-thumbnail ^
    -o "downloads\thumbs\%%(title)s [%%(id)s].%%(ext)s" ^
    "%URL%"
)

echo.
pause
goto main

:mode_list_subs
call :get_url
cls
echo Обычные субтитры:
echo.
yt-dlp.exe --list-subs --skip-download "%URL%"
echo.
pause
goto main

:mode_list_auto_subs
call :get_url
cls
echo Автоматические субтитры:
echo.
yt-dlp.exe --list-subs --write-auto-subs --skip-download "%URL%"
echo.
pause
goto main

:mode_subs
call :ensure_dirs
call :get_url
call :choose_sub_langs
call :choose_sub_format
cls
echo Скачивание: обычные субтитры
echo Языки: %SUBLANGS%
echo Формат: %SUBFMT%
echo.
yt-dlp.exe ^
--newline ^
--ignore-errors ^
--skip-download ^
--write-subs ^
--sub-langs "%SUBLANGS%" ^
--sub-format "%SUBFMT%" ^
-o "downloads\subs\%%(title)s [%%(id)s].%%(ext)s" ^
"%URL%"
echo.
pause
goto main

:mode_auto_subs
call :ensure_dirs
call :get_url
call :choose_sub_langs
call :choose_sub_format
cls
echo Скачивание: автоматические субтитры
echo Языки: %SUBLANGS%
echo Формат: %SUBFMT%
echo.
yt-dlp.exe ^
--newline ^
--ignore-errors ^
--skip-download ^
--write-auto-subs ^
--sub-langs "%SUBLANGS%" ^
--sub-format "%SUBFMT%" ^
-o "downloads\subs\%%(title)s [%%(id)s].%%(ext)s" ^
"%URL%"
echo.
pause
goto main

:mode_video_subs
call :ensure_dirs
call :get_url
call :choose_sub_langs
call :choose_sub_format
call :choose_video_container
cls
echo Скачивание: видео + обычные субтитры
echo Языки: %SUBLANGS%
echo Формат субтитров: %SUBFMT%
if defined VIDFMT echo Контейнер видео: %VIDFMT%
if not defined VIDFMT echo Контейнер видео: как есть
echo.

if defined VIDFMT (
    yt-dlp.exe ^
    --newline ^
    --ignore-errors ^
    -f "bestvideo+bestaudio/best" ^
    --merge-output-format %VIDFMT% ^
    --write-subs ^
    --sub-langs "%SUBLANGS%" ^
    --sub-format "%SUBFMT%" ^
    --embed-subs ^
    --add-metadata ^
    -o "downloads\video\%%(title)s [%%(id)s].%%(ext)s" ^
    "%URL%"
) else (
    yt-dlp.exe ^
    --newline ^
    --ignore-errors ^
    -f "bestvideo+bestaudio/best" ^
    --write-subs ^
    --sub-langs "%SUBLANGS%" ^
    --sub-format "%SUBFMT%" ^
    --embed-subs ^
    --add-metadata ^
    -o "downloads\video\%%(title)s [%%(id)s].%%(ext)s" ^
    "%URL%"
)

echo.
pause
goto main

:mode_video_auto_subs
call :ensure_dirs
call :get_url
call :choose_sub_langs
call :choose_sub_format
call :choose_video_container
cls
echo Скачивание: видео + автоматические субтитры
echo Языки: %SUBLANGS%
echo Формат субтитров: %SUBFMT%
if defined VIDFMT echo Контейнер видео: %VIDFMT%
if not defined VIDFMT echo Контейнер видео: как есть
echo.

if defined VIDFMT (
    yt-dlp.exe ^
    --newline ^
    --ignore-errors ^
    -f "bestvideo+bestaudio/best" ^
    --merge-output-format %VIDFMT% ^
    --write-auto-subs ^
    --sub-langs "%SUBLANGS%" ^
    --sub-format "%SUBFMT%" ^
    --embed-subs ^
    --add-metadata ^
    -o "downloads\video\%%(title)s [%%(id)s].%%(ext)s" ^
    "%URL%"
) else (
    yt-dlp.exe ^
    --newline ^
    --ignore-errors ^
    -f "bestvideo+bestaudio/best" ^
    --write-auto-subs ^
    --sub-langs "%SUBLANGS%" ^
    --sub-format "%SUBFMT%" ^
    --embed-subs ^
    --add-metadata ^
    -o "downloads\video\%%(title)s [%%(id)s].%%(ext)s" ^
    "%URL%"
)

echo.
pause
goto main

:mode_formats
call :get_url
cls
echo Доступные форматы:
echo.
yt-dlp.exe -F "%URL%"
echo.
pause
goto main

:batch_menu
call :ensure_dirs
if not exist "%LINKS%" (
    echo Файл %LINKS% не найден
    echo.
    echo Создай его и вставь по одной ссылке на строку
    echo.
    pause
    goto main
)

cls
echo ===============================
echo     РЕЖИМ links.txt
echo ===============================
echo.
echo 1^) Лучшее видео + аудио
echo 2^) MP4
echo 3^) MP3
echo 4^) Только превью
echo 5^) Обычные субтитры
echo 6^) Автоматические субтитры
echo.
set /p BMODE=Выбери режим для links.txt: 

if "%BMODE%"=="1" goto batch_best
if "%BMODE%"=="2" goto batch_mp4
if "%BMODE%"=="3" goto batch_mp3
if "%BMODE%"=="4" goto batch_thumb
if "%BMODE%"=="5" goto batch_subs
if "%BMODE%"=="6" goto batch_auto_subs

echo Неверный выбор
pause
goto main

:batch_best
for /f "usebackq delims=" %%i in ("%LINKS%") do (
    if not "%%~i"=="" (
        echo.
        echo ==== %%i ====
        yt-dlp.exe ^
        --newline ^
        --ignore-errors ^
        --add-metadata ^
        -o "downloads\video\%%(title)s [%%(id)s].%%(ext)s" ^
        "%%i"
    )
)
echo.
pause
goto main

:batch_mp4
for /f "usebackq delims=" %%i in ("%LINKS%") do (
    if not "%%~i"=="" (
        echo.
        echo ==== %%i ====
        yt-dlp.exe ^
        --newline ^
        --ignore-errors ^
        -f "bestvideo+bestaudio/best" ^
        --merge-output-format mp4 ^
        --add-metadata ^
        -o "downloads\video\%%(title)s [%%(id)s].%%(ext)s" ^
        "%%i"
    )
)
echo.
pause
goto main

:batch_mp3
for /f "usebackq delims=" %%i in ("%LINKS%") do (
    if not "%%~i"=="" (
        echo.
        echo ==== %%i ====
        yt-dlp.exe ^
        --newline ^
        --ignore-errors ^
        -x ^
        --audio-format mp3 ^
        --audio-quality 0 ^
        --add-metadata ^
        --embed-thumbnail ^
        -o "downloads\audio\%%(title)s [%%(id)s].%%(ext)s" ^
        "%%i"
    )
)
echo.
pause
goto main

:batch_thumb
for /f "usebackq delims=" %%i in ("%LINKS%") do (
    if not "%%~i"=="" (
        echo.
        echo ==== %%i ====
        yt-dlp.exe ^
        --newline ^
        --ignore-errors ^
        --skip-download ^
        --write-thumbnail ^
        --convert-thumbnails jpg ^
        -o "downloads\thumbs\%%(title)s [%%(id)s].%%(ext)s" ^
        "%%i"
    )
)
echo.
pause
goto main

:batch_subs
call :choose_sub_langs
for /f "usebackq delims=" %%i in ("%LINKS%") do (
    if not "%%~i"=="" (
        echo.
        echo ==== %%i ====
        yt-dlp.exe ^
        --newline ^
        --ignore-errors ^
        --skip-download ^
        --write-subs ^
        --sub-langs "%SUBLANGS%" ^
        --sub-format "best/srt/vtt" ^
        -o "downloads\subs\%%(title)s [%%(id)s].%%(ext)s" ^
        "%%i"
    )
)
echo.
pause
goto main

:batch_auto_subs
call :choose_sub_langs
for /f "usebackq delims=" %%i in ("%LINKS%") do (
    if not "%%~i"=="" (
        echo.
        echo ==== %%i ====
        yt-dlp.exe ^
        --newline ^
        --ignore-errors ^
        --skip-download ^
        --write-auto-subs ^
        --sub-langs "%SUBLANGS%" ^
        --sub-format "best/srt/vtt" ^
        -o "downloads\subs\%%(title)s [%%(id)s].%%(ext)s" ^
        "%%i"
    )
)
echo.
pause
goto main

:open_downloads
call :ensure_dirs
start "" "%cd%\downloads"
goto main