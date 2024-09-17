#!/bin/bash

sudo mount -o loop forensic_tools.iso /media
cd /media || exit
sudo ./init.sh
which ls
ldd "$(which ls)"