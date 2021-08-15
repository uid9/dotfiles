#!/bin/sh

export CM_DIR=~/.cache

[[ "$(</sys/class/drm/card0-HDMI-A-2/enabled)" == "enabled" ]] && xrandr --output HDMI2 --primary --auto --output eDP1 --off || true
slock &
~/.fehbg
xrdb .Xresources
xinput --disable "Elan Touchpad"
clipmenud &
redshift -r &
urxvtd &
sxhkd &
exec bspwm
