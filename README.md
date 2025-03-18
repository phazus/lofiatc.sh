# lofiatc.sh

Small bash file that implements https://www.lofiatc.com with two running [mpv](https://mpv.io/) instances.

Because of LiveATC's [Terms of Service](https://www.liveatc.net/legal/), the links to their streams have been replaced by freely available YouTube videos.

Support for [Broadcastify's top feeds](https://www.broadcastify.com/listen/top) has been added if you want to listen to live feeds.

```
$ ./lofiatc.sh
ATC: KLAX
  Los Angeles International Airport
  https://www.youtube.com/watch?v=Q9zwUZr6yPA
  Volume: 80
Lofi: lofimp3.m3u
  Volume: 100

Use / and * to adjust lofi volume
To also adjust ATC volume, start with `bash --init-file lofiatc.sh` and use bash's job control
```

# Getting started

```sh
git clone https://github.com/phazus/lofiatc.sh.git
cd lofiatc.sh
./lofiatc.sh
```

