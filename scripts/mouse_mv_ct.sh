#!/bin/bash
 
###############################################################################
#
# 概要
#
#     マウスポインタを画面間移動させる(center)
###############################################################################
#
#~$ sudo apt-get install xautomation
# 設定
#
# ディスプレイ設定
#
#export DISPLAY=:0
#XTE="xte -x$DISPLAY"
XPOS='xmousepos'
#
# 固定の幅や高さ
#
#DISPLAY_HEAD_BAR_Y=25
 
#
# マウスポジション xmousepos (X Y x y) で確認
#
#CENTER_POS="2240 600"
#RIGHT_POS="4160 540"
#LEFT_POS="640 512"
source ${HOME}/.bash_envs
source ${SCRIPT_PACKAGE_PATH}/mouse_mv_pos.sh
# echo ${x_ct}

###############################################################################
#
# 実行
#
xte "mousemove ${x_ct} ${y_ct}"
# xte 'mousemove 2240 600'
xte "sleep 0.1"
xte "mousedown 3"
xte "mouseclick 1"
xte "mouseup 3"

xte "usleep 300000"
xte "key Alt_L"
xte "usleep 150000"
xte "key Escape"
xte "key Escape"

#xte "mouseclick 1"
#$XTE "mouseclick 2"

exit 0
