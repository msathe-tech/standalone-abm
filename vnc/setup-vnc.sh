#!/bin/bash
echo '==== Upgrade system ===='
sudo apt-get update
sudo apt-get upgrade -y
 
echo '==== Install packages ===='
sudo apt-get install -y gnome-shell
sudo apt-get install -y ubuntu-gnome-desktop
sudo apt-get install -y autocutsel
sudo apt-get install -y tightvncserver
sudo apt-get install -y gnome-core
sudo apt-get install -y gnome-panel
sudo apt-get install -y synaptic
sudo apt-get install -y virt-viewer
 
touch ~/.Xresources
 
# next start the server, giving a passwd etc
vncserver -geometry 1920x1080