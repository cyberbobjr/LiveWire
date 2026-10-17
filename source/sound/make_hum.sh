#!/bin/sh
# Live Wire inverter hum: soft 100 Hz electrical buzz with harmonics (no high
# whine), 2 s mono loop (an integer number of periods of every partial).
# Needs ffmpeg with libvorbis. Run from the project root.
ffmpeg -y -f lavfi -i "aevalsrc='0.30*sin(2*PI*100*t)+0.18*sin(2*PI*200*t)+0.10*sin(2*PI*300*t)+0.06*sin(2*PI*400*t)+0.04*sin(2*PI*600*t)':s=44100:d=2" \
  -ac 1 -c:a libvorbis -q:a 5 Contents/mods/batman_LiveWire/42.21/media/sound/LiveWireInverterHum.ogg
