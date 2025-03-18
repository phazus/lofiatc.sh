#!/bin/bash
set -m

LOFI_PLAYLIST="lofimp3.m3u" # Options: 'lofiyt.m3u', 'lofimp3.m3u'
ATC_PLAYLIST="icao.txt"     # Options: 'broadcastify.txt', 'icao.txt'
LOFI_VOLUME=100
ATC_VOLUME=80

function updateinfo()
# hacky but it seems to work
# todo robust error handling
{
    echo "Updating stream information..." >&2

    LOFI_YT="lofiyt.m3u"
    LOFI_MP3="lofimp3.m3u"
    BROADCASTIFY="broadcastify.txt"
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

    # get top broadcastify streams
    echo "Broadcastify top streams" >&2
    curl https://www.broadcastify.com/listen/top 2>/dev/null \
        | awk '/stid/{c=4};c&&((c-- == 4) || (c==0))' \
        > prefilter

    grep -o 'stid/[0-9]\+">[A-Z>]\+' prefilter \
        | sed -e 's/[^A-Z]\+//' \
        > stids

    sed -ne 's/.*\/listen\/feed\/\([0-9]\+">[^<]\+\).*/http:\/\/broadcastify.cdnstream1.com\/\1/p' prefilter \
        | sed -e 's/\(.*\)">\(.*\)/\2;\1/' \
        > feeds

    paste -d ";" stids feeds > $BROADCASTIFY
    rm prefilter stids feeds
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

ATC_ENTRY=$(sort --random-sort $ATC_PLAYLIST | head -1)
ATC_CODE=$(echo $ATC_ENTRY | cut -d ";" -f1)
ATC_NAME=$(echo $ATC_ENTRY | cut -d ";" -f2)
ATC_FEED=$(echo $ATC_ENTRY | cut -d ";" -f3)

echo "ATC: $ATC_CODE"
echo "  $ATC_NAME"
echo "  $ATC_FEED"
echo "  Volume: $ATC_VOLUME"

mpv --no-video --loop --volume="$ATC_VOLUME" "$ATC_FEED" &
MPV_ATC_PID=$!

# Play LOFI
echo "Lofi: $LOFI_PLAYLIST" >&2
echo "  Volume: $LOFI_VOLUME"

echo -e "\nUse / and * to adjust lofi volume" >&2
echo -e "To also adjust ATC volume, start with \`bash --init-file lofiatc.sh\` and use bash's job control\n" >&2
mpv --no-video --shuffle --volume="$LOFI_VOLUME" --loop-playlist "$LOFI_PLAYLIST" &
MPV_LOFI_PID=$!

# Ensure that both MPV instances are closed when the script terminates
trap "ps -p $MPV_LOFI_PID >/dev/null && kill $MPV_LOFI_PID; \
      ps -p $MPV_ATC_PID >/dev/null && kill $MPV_ATC_PID; \
      wait $MPV_ATC_PID;" EXIT

# Bring LOFI job to foreground
fg
