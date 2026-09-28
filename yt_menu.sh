#!/usr/bin/env bash

# Always work from the repository directory
cd "$(dirname "$(readlink -f "$0")")" || exit 1

ROOT="$PWD"
TOOLS="$ROOT/tools"
DENO_INSTALL="$TOOLS/deno"

# Все инструменты берутся из папки проекта (tools), а не из системного PATH.
export DENO_INSTALL
export PATH="$TOOLS:$DENO_INSTALL/bin:$TOOLS/ffmpeg/bin:$PATH"

YTDLP="$TOOLS/yt-dlp"
LINKS="downloads/links.txt"

OUT_VIDEO="downloads/video/%(title)s [%(id)s].%(ext)s"
OUT_AUDIO="downloads/audio/%(title)s [%(id)s].%(ext)s"
OUT_THUMB="downloads/thumbs/%(title)s [%(id)s].%(ext)s"
OUT_SUBS="downloads/subs/%(title)s [%(id)s].%(ext)s"

if [[ ! -x "$YTDLP" || ! -x "$TOOLS/ffmpeg/bin/ffmpeg" || ! -x "$DENO_INSTALL/bin/deno" ]]; then
    echo "Не найдены нужные инструменты в папке tools"
    echo "Сначала запусти ./setup.sh"
    exit 1
fi

# ---- Вспомогательные функции -------------------------------------------------

pause() {
    echo
    read -rp "Нажми Enter, чтобы продолжить..." _
}

trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

ensure_dirs() {
    mkdir -p downloads/video downloads/audio downloads/thumbs downloads/subs
}

get_url() {
    echo
    URL=""
    read -rp "Вставь ссылку: " URL
    URL="$(trim "$URL")"
    if [[ -z "$URL" ]]; then
        echo "Ссылка пустая"
        pause
        return 1
    fi
}

choose_sub_langs() {
    clear
    echo "==============================="
    echo "     ВЫБОР ЯЗЫКОВ СУБТИТРОВ"
    echo "==============================="
    echo
    echo "1) Японский            (ja)"
    echo "2) Английский          (en)"
    echo "3) Русский             (ru)"
    echo "4) Японский + Английский       (ja,en)"
    echo "5) Японский + Русский          (ja,ru)"
    echo "6) Английский + Русский        (en,ru)"
    echo "7) Японский + Английский + Русский  (ja,en,ru)"
    echo "8) Ввести коды вручную"
    echo

    SUBLANGS=""
    local choice
    read -rp "Выбери вариант: " choice

    case "$choice" in
        1) SUBLANGS="ja" ;;
        2) SUBLANGS="en" ;;
        3) SUBLANGS="ru" ;;
        4) SUBLANGS="ja,en" ;;
        5) SUBLANGS="ja,ru" ;;
        6) SUBLANGS="en,ru" ;;
        7) SUBLANGS="ja,en,ru" ;;
        8)
            echo
            echo "Примеры: ja  или  ja,en  или  ru"
            read -rp "Введи коды языков: " SUBLANGS
            SUBLANGS="$(trim "$SUBLANGS")"
            ;;
    esac

    if [[ -z "$SUBLANGS" ]]; then
        echo
        echo "Неверный выбор"
        pause
        return 1
    fi

    SUBLANGS="$SUBLANGS,-live_chat"
}

choose_video_container() {
    clear
    echo "==============================="
    echo "     ФОРМАТ ВИДЕО"
    echo "==============================="
    echo
    echo "1) MP4"
    echo "2) MKV"
    echo "3) WEBM"
    echo "4) Как есть (без принудительного контейнера)"
    echo

    VIDFMT=""
    local choice
    read -rp "Выбери формат: " choice

    case "$choice" in
        1) VIDFMT="mp4" ;;
        2) VIDFMT="mkv" ;;
        3) VIDFMT="webm" ;;
        4) VIDFMT="" ;;
        *)
            echo
            echo "Неверный выбор"
            pause
            return 1
            ;;
    esac
}

choose_audio_format() {
    clear
    echo "==============================="
    echo "     ФОРМАТ АУДИО"
    echo "==============================="
    echo
    echo "1) MP3"
    echo "2) M4A"
    echo "3) WAV"
    echo "4) FLAC"
    echo "5) OPUS"
    echo "6) Как есть (без перекодирования)"
    echo

    AUDFMT=""
    local choice
    read -rp "Выбери формат: " choice

    case "$choice" in
        1) AUDFMT="mp3" ;;
        2) AUDFMT="m4a" ;;
        3) AUDFMT="wav" ;;
        4) AUDFMT="flac" ;;
        5) AUDFMT="opus" ;;
        6) AUDFMT="" ;;
        *)
            echo
            echo "Неверный выбор"
            pause
            return 1
            ;;
    esac
}

choose_sub_format() {
    clear
    echo "==============================="
    echo "     ФОРМАТ СУБТИТРОВ"
    echo "==============================="
    echo
    echo "1) SRT"
    echo "2) VTT"
    echo "3) TTML"
    echo "4) Best (что лучше доступно)"
    echo

    SUBFMT=""
    local choice
    read -rp "Выбери формат: " choice

    case "$choice" in
        1) SUBFMT="srt" ;;
        2) SUBFMT="vtt" ;;
        3) SUBFMT="ttml" ;;
        4) SUBFMT="best" ;;
        *)
            echo
            echo "Неверный выбор"
            pause
            return 1
            ;;
    esac
}

choose_thumb_format() {
    clear
    echo "==============================="
    echo "     ФОРМАТ ПРЕВЬЮ"
    echo "==============================="
    echo
    echo "1) JPG"
    echo "2) PNG"
    echo "3) WEBP"
    echo "4) Как есть (без конвертации)"
    echo

    THUMBFMT=""
    local choice
    read -rp "Выбери формат: " choice

    case "$choice" in
        1) THUMBFMT="jpg" ;;
        2) THUMBFMT="png" ;;
        3) THUMBFMT="webp" ;;
        4) THUMBFMT="" ;;
        *)
            echo
            echo "Неверный выбор"
            pause
            return 1
            ;;
    esac
}

# ---- Функции скачивания (URL всегда последний аргумент) ---------------------
# Используются и для одиночных ссылок, и для links.txt

dl_best() {   # URL
    "$YTDLP" \
        --newline \
        --ignore-errors \
        --add-metadata \
        -o "$OUT_VIDEO" \
        "$1"
}

dl_video() {   # CONTAINER URL
    local container="$1" url="$2"
    local args=(--newline --ignore-errors -f "bestvideo+bestaudio/best")
    [[ -n "$container" ]] && args+=(--merge-output-format "$container")
    args+=(--add-metadata -o "$OUT_VIDEO" "$url")
    "$YTDLP" "${args[@]}"
}

dl_audio() {   # FORMAT URL
    local fmt="$1" url="$2"
    if [[ -n "$fmt" ]]; then
        "$YTDLP" \
            --newline \
            --ignore-errors \
            -x \
            --audio-format "$fmt" \
            --audio-quality 0 \
            --add-metadata \
            --embed-thumbnail \
            -o "$OUT_AUDIO" \
            "$url"
    else
        "$YTDLP" \
            --newline \
            --ignore-errors \
            -f "bestaudio/best" \
            --add-metadata \
            -o "$OUT_AUDIO" \
            "$url"
    fi
}

dl_thumb() {   # FORMAT URL
    local fmt="$1" url="$2"
    local args=(--newline --ignore-errors --skip-download --write-thumbnail)
    [[ -n "$fmt" ]] && args+=(--convert-thumbnails "$fmt")
    args+=(-o "$OUT_THUMB" "$url")
    "$YTDLP" "${args[@]}"
}

dl_subs() {   # FLAG(--write-subs|--write-auto-subs) LANGS SUBFORMAT URL
    "$YTDLP" \
        --newline \
        --ignore-errors \
        --skip-download \
        "$1" \
        --sub-langs "$2" \
        --sub-format "$3" \
        -o "$OUT_SUBS" \
        "$4"
}

dl_video_subs() {   # FLAG LANGS SUBFORMAT CONTAINER URL
    local flag="$1" langs="$2" subfmt="$3" container="$4" url="$5"
    local args=(--newline --ignore-errors -f "bestvideo+bestaudio/best")
    [[ -n "$container" ]] && args+=(--merge-output-format "$container")
    args+=("$flag" --sub-langs "$langs" --sub-format "$subfmt" --embed-subs --add-metadata -o "$OUT_VIDEO" "$url")
    "$YTDLP" "${args[@]}"
}

# Запускает переданную команду для каждой ссылки из links.txt (ссылка = последний аргумент).
# Файл читается через fd 3, чтобы yt-dlp не съедал stdin.
for_each_link() {
    local url
    while IFS= read -r -u 3 url || [[ -n "$url" ]]; do
        url="${url%$'\r'}"
        url="$(trim "$url")"
        [[ -z "$url" ]] && continue
        echo
        echo "==== $url ===="
        "$@" "$url"
    done 3< "$LINKS"
}

# ---- Режимы -----------------------------------------------------------------

mode_best() {
    ensure_dirs
    get_url || return
    clear
    echo "Скачивание: лучшее доступное качество"
    echo
    dl_best "$URL"
    pause
}

mode_mp4() {
    ensure_dirs
    get_url || return
    choose_video_container || return
    clear
    echo "Скачивание: лучшее видео/аудио"
    if [[ -n "$VIDFMT" ]]; then echo "Контейнер: $VIDFMT"; else echo "Контейнер: как есть"; fi
    echo
    dl_video "$VIDFMT" "$URL"
    pause
}

mode_mp3() {
    ensure_dirs
    get_url || return
    choose_audio_format || return
    clear
    echo "Скачивание: аудио"
    if [[ -n "$AUDFMT" ]]; then echo "Формат: $AUDFMT"; else echo "Формат: как есть"; fi
    echo
    dl_audio "$AUDFMT" "$URL"
    pause
}

mode_thumb() {
    ensure_dirs
    get_url || return
    choose_thumb_format || return
    clear
    echo "Скачивание: только превью"
    if [[ -n "$THUMBFMT" ]]; then echo "Формат: $THUMBFMT"; else echo "Формат: как есть"; fi
    echo
    dl_thumb "$THUMBFMT" "$URL"
    pause
}

mode_list_subs() {
    get_url || return
    clear
    echo "Обычные субтитры:"
    echo
    "$YTDLP" --list-subs --skip-download "$URL"
    pause
}

mode_list_auto_subs() {
    get_url || return
    clear
    echo "Автоматические субтитры:"
    echo
    "$YTDLP" --list-subs --write-auto-subs --skip-download "$URL"
    pause
}

mode_subs() {
    ensure_dirs
    get_url || return
    choose_sub_langs || return
    choose_sub_format || return
    clear
    echo "Скачивание: обычные субтитры"
    echo "Языки: $SUBLANGS"
    echo "Формат: $SUBFMT"
    echo
    dl_subs --write-subs "$SUBLANGS" "$SUBFMT" "$URL"
    pause
}

mode_auto_subs() {
    ensure_dirs
    get_url || return
    choose_sub_langs || return
    choose_sub_format || return
    clear
    echo "Скачивание: автоматические субтитры"
    echo "Языки: $SUBLANGS"
    echo "Формат: $SUBFMT"
    echo
    dl_subs --write-auto-subs "$SUBLANGS" "$SUBFMT" "$URL"
    pause
}

mode_video_subs() {
    ensure_dirs
    get_url || return
    choose_sub_langs || return
    choose_sub_format || return
    choose_video_container || return
    clear
    echo "Скачивание: видео + обычные субтитры"
    echo "Языки: $SUBLANGS"
    echo "Формат субтитров: $SUBFMT"
    if [[ -n "$VIDFMT" ]]; then echo "Контейнер видео: $VIDFMT"; else echo "Контейнер видео: как есть"; fi
    echo
    dl_video_subs --write-subs "$SUBLANGS" "$SUBFMT" "$VIDFMT" "$URL"
    pause
}

mode_video_auto_subs() {
    ensure_dirs
    get_url || return
    choose_sub_langs || return
    choose_sub_format || return
    choose_video_container || return
    clear
    echo "Скачивание: видео + автоматические субтитры"
    echo "Языки: $SUBLANGS"
    echo "Формат субтитров: $SUBFMT"
    if [[ -n "$VIDFMT" ]]; then echo "Контейнер видео: $VIDFMT"; else echo "Контейнер видео: как есть"; fi
    echo
    dl_video_subs --write-auto-subs "$SUBLANGS" "$SUBFMT" "$VIDFMT" "$URL"
    pause
}

mode_formats() {
    get_url || return
    clear
    echo "Доступные форматы:"
    echo
    "$YTDLP" -F "$URL"
    pause
}

batch_menu() {
    ensure_dirs
    if [[ ! -f "$LINKS" ]]; then
        echo "Файл $LINKS не найден"
        echo
        echo "Создай его и вставь по одной ссылке на строку"
        echo
        pause
        return
    fi

    clear
    echo "==============================="
    echo "    РЕЖИМ links.txt"
    echo "==============================="
    echo
    echo "1) Лучшее видео + аудио"
    echo "2) MP4"
    echo "3) MP3"
    echo "4) Только превью"
    echo "5) Обычные субтитры"
    echo "6) Автоматические субтитры"
    echo

    local bmode
    read -rp "Выбери режим для links.txt: " bmode

    case "$bmode" in
        1) for_each_link dl_best ;;
        2) for_each_link dl_video mp4 ;;
        3) for_each_link dl_audio mp3 ;;
        4) for_each_link dl_thumb jpg ;;
        5)
            choose_sub_langs || return
            for_each_link dl_subs --write-subs "$SUBLANGS" "best/srt/vtt"
            ;;
        6)
            choose_sub_langs || return
            for_each_link dl_subs --write-auto-subs "$SUBLANGS" "best/srt/vtt"
            ;;
        *)
            echo "Неверный выбор"
            pause
            return
            ;;
    esac

    pause
}

open_downloads() {
    ensure_dirs
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$ROOT/downloads" >/dev/null 2>&1 &
    else
        echo "xdg-open не найден. Папка загрузок: $ROOT/downloads"
        pause
    fi
}

# ---- Главное меню -----------------------------------------------------------

while true; do
    clear
    echo "=========================================="
    echo "             YT-DLP MENU"
    echo "=========================================="
    echo
    echo " 1 ) Лучшее видео + аудио (макс. качество)"
    echo " 2 ) Лучшее видео + аудио в MP4"
    echo " 3 ) Только аудио MP3"
    echo " 4 ) Только превью"
    echo " 5 ) Показать обычные субтитры"
    echo " 6 ) Показать автоматические субтитры"
    echo " 7 ) Скачать обычные субтитры"
    echo " 8 ) Скачать автоматические субтитры"
    echo " 9 ) Видео + обычные субтитры"
    echo "10 ) Видео + автоматические субтитры"
    echo "11 ) Показать доступные форматы видео/аудио"
    echo "12 ) Скачать всё из links.txt"
    echo "13 ) Открыть папку загрузки"
    echo " 0 ) Выход"
    echo

    MODE=""
    read -rp "Выбери пункт: " MODE || exit 0   # Ctrl+D / закрытый stdin = выход

    case "$MODE" in
        1)  mode_best ;;
        2)  mode_mp4 ;;
        3)  mode_mp3 ;;
        4)  mode_thumb ;;
        5)  mode_list_subs ;;
        6)  mode_list_auto_subs ;;
        7)  mode_subs ;;
        8)  mode_auto_subs ;;
        9)  mode_video_subs ;;
        10) mode_video_auto_subs ;;
        11) mode_formats ;;
        12) batch_menu ;;
        13) open_downloads ;;
        0)  exit 0 ;;
        *)
            echo
            echo "Неверный пункт"
            pause
            ;;
    esac
done