#!/bin/sh
# Live Wire water pump hum: light motor whir (50 Hz hum with a 150 Hz and a 250 Hz
# partial, slow 4 Hz throb), 2 s mono loop (an integer number of periods of every
# partial). Needs ffmpeg with libvorbis. Run from the project root.
ffmpeg -y -f lavfi -i "aevalsrc='(0.22*sin(2*PI*50*t)+0.12*sin(2*PI*150*t)+0.06*sin(2*PI*250*t))*(0.85+0.15*sin(2*PI*4*t))':s=44100:d=2" \
  -ac 1 -c:a libvorbis -q:a 5 Contents/mods/batman_LiveWire/42.21/media/sound/LiveWirePumpHum.ogg
