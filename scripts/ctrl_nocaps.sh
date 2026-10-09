#!/bin/bash

dconf reset /org/gnome/settings-daemon/plugins/keyboard/active

dconf write /org/gnome/desktop/input-sources/xkb-options "['ctrl:nocaps']"

# gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"

