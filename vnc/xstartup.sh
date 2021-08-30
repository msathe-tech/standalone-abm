#!/bin/sh


# the config file is located at $HOME/.vnc/xstartup
# copy below content into it and restart the vncserver with below cmd:
# vncserver -kill :1
# vncserver -geometry 1920x1080
# gcloud compute firewall-rules create vncserver --allow tcp:5901 --source-ranges 0.0.0.0/0


export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin:$PATH
 
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
autocutsel -fork
xsetroot -solid grey
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP="GNOME-Flashback:Unity"
export XDG_MENU_PREFIX="gnome-flashback-"
unset DBUS_SESSION_BUS_ADDRESS
gnome-session --session=gnome-flashback-metacity --disable-acceleration-check --debug &