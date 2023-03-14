#!/bin/bash

ICAO_CODES=icao.txt
LOFI_YT=lofiyt.m3u
LOFI_MP3=lofimp3.m3u

function updateinfo()
# hacky but it seems to work
# todo robust error handling
{
    echo "Updating stream information..." >&2

    CHUNK_URL="https://www.lofiatc.com$(curl https://www.lofiatc.com/ 2>/dev/null | grep -o '/static/js/main.[^.]\+.chunk.js')"

    # get youtube links for lofi songs
    echo "Youtube song links" >&2
    echo -e $(curl "$CHUNK_URL" 2>/dev/null) \
        | grep -o 'youtube:"[^"]\+youtube.com/watch[^"]\+' \
        | sed -e 's/youtube:"//' \
        > $LOFI_YT
    echo "DONE" >&2

    # get mp3s as stored on lofiatc.com
    echo "mp3 URIs" >&2
    echo -e $(curl "$CHUNK_URL" 2>/dev/null) \
        | grep -o 'name:"[^"]\+",youtube' \
        | sed -e 's/name:"\([^"]\+\)",youtube/\1/' \
        | perl -MURI::Escape -wlne 'print uri_escape $_' \
        | sed -e 's/\(.*\)/https:\/\/www.lofiatc.com\/assets\/music\/\1.mp3/' \
        > $LOFI_MP3
    echo "DONE" >&2

    # respect liveact's toc:
    # https://www.liveatc.net/legal/
    
    # get all icao codes
    # echo "ICAO codes" >&2
    # ICAO_CODES_TEMP=$(mktemp)
    # for c in {a..z} ; do
    #     echo "$c" >&2
    #     curl 'https://www.lofiatc.com/autocomplete/'$c'?icao=KAPA:1' 2>/dev/null \
    #         | jq --raw-output '.codes[]' \
    #         >> $ICAO_CODES_TEMP
    # done

    # echo "ICAO links" >&2
    # rm -f $ICAO_CODES
    # for c in $(sort $ICAO_CODES_TEMP | uniq) ; do
    #     echo $c >&2
    #     ICAO_INFO=$(curl "https://www.lofiatc.com/airport/$c" 2>/dev/null)
    #     ICAO_CODE=$(echo $ICAO_INFO | jq --raw-output '.icao')
    #     ICAO_NAME=$(echo $ICAO_INFO | jq --raw-output '.name')
    #     ICAO_FEED=$(echo $ICAO_INFO | jq --raw-output '.feedUrl')
    #     echo "$ICAO_CODE;$ICAO_NAME;$ICAO_FEED" >> $ICAO_CODES
    # done
    # rm -f $ICAO_CODES_TEMP

    # echo "DONE" >&2
}


[[ "${1:-}" == "update" ]] && updateinfo

# play random ATC stream
ICAO_ENTRY=$(sort --random-sort $ICAO_CODES | head -1)
ICAO_CODE=$(echo $ICAO_ENTRY | cut -d ";" -f1)
ICAO_NAME=$(echo $ICAO_ENTRY | cut -d ";" -f2)
ICAO_FEED=$(echo $ICAO_ENTRY | cut -d ";" -f3)
echo "Playing: $ICAO_CODE - $ICAO_NAME" >&2
echo $ICAO_FEED >&2
mpv --no-video --loop "$ICAO_FEED" &>/dev/null &

# lofi playlist
# in case yt videos shall be used for playback:
# https://github.com/yt-dlp/yt-dlp/issues/6496#issuecomment-1463202877
mpv --no-ytdl --no-video --shuffle --loop-playlist $LOFI_YT
