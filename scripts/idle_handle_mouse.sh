#!/bin/bash

# apt install xprintidle

function run_with_sleep()
{
  # XPOS=(`xmousepos`)
  XPOS=`xmousepos`
  echo "Xcursor.size: 1000" > ~/.Xresources
  gsettings set com.canonical.Unity.Interface cursor-scale-factor 2
  # xte "mousemove $((XPOS[0]+1)) $((XPOS[1]+1)) $((XPOS[2]+1)) $((XPOS[3]+1))"
  xte "mousemove 0 0 0 0"
  xte "sleep 0.1"
  xte "mousemove ${XPOS}"
}

function run_with_wakeup()
{
  echo -n "" > ~/.Xresources
  gsettings reset com.canonical.Unity.Interface cursor-scale-factor
  natural_scrolling
}

function timer()
{
  loop_rate=1
  inactive_timer=$((1*1000*60)) #1m

  flag_sleep=false

  while [ "$key" = "" ]
  do
    inactive_last=${inactive}
    inactive=`xprintidle`

    if [ $inactive_timer -lt $inactive ]; then # sleep
      if ! "${flag_sleep}"; then
        run_with_sleep
        flag_sleep=true
        inactive_last=0
        inactive=0
      fi
    else # active
      if "${flag_sleep}"; then
        if [ $inactive -lt $inactive_last ]; then
          run_with_wakeup
          flag_sleep=false
        fi
      fi
    fi

    read -t ${loop_rate} key
  done
}

run_with_wakeup
timer

