#!/bin/bash

HISTORY_FILE="${HOME}/.bash_history_uniq"

awk -v histtimeformat="$HISTTIMEFORMAT" '
BEGIN {
    # strftime format string
    format = histtimeformat
}
{
    if ($0 ~ /^#/) {
        unix_time = substr($0, 2)
        datetime = strftime(format, unix_time)
    } else {
        print datetime $0
    }
}
' "$HISTORY_FILE"

