#/bin/bash

ifconfig | grep "\(broadcast\|ブロードキャスト\)" | grep -o "inet[^0-9]*[0-9]\{3\}\.[0-9]\{3\}.[0-9].[0-9]\{3\}" | grep -o [0-9].*

