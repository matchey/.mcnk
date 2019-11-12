
vimTerm()
{
  if [ "$VIM_TERMINAL" ]; then
    fname="$@"
    printf '\e]51;["call","Tapi_InTermEdit",["%s","%s"]]\x07' "${PWD}" "${fname}"
  else
    vimv "$@" || return $?
  fi
}

function vims(){
  \vim -c "LoadSession $1"
}

function vimv(){
    if [ $# -eq 2 ];then
        \vim -O2 $@
    elif [ $# -eq 3 ];then
        \vim -O2 $1 $2 -c "New $3" -c "tabnext"
    elif [ $# -eq 4 ];then
        \vim -O2 $1 $2 -c "New $3 $4" -c "tabnext"
    elif [ $# -eq 6 ];then
        \vim -O2 $1 $2 -c "New $3 $4" -c "New $5 $6" -c "tabnext"
    else
        \vim $@
    fi
}

function vertNTermCmd(){
  cmd=""
  if [ $# -eq 0 ];then
      echo -c "terminal ++close ++curwin"
  elif [ $# -eq 1 ];then
    if [ $1 -eq 2 ];then
      echo -c "vnew" -c "windo terminal ++close ++curwin" -c "wincmd t"
    elif [ $1 -eq 3 ];then
      echo -c "vnew" -c "vnew" -c "windo terminal ++close ++curwin" -c "wincmd t"
    elif [ $1 -eq 4 ];then
      echo -c "vnew" -c "windo new" -c "windo terminal ++close ++curwin" -c "wincmd t"
    elif [ $1 -eq 6 ];then
      echo -c "new" -c "new" -c "windo vnew" -c "windo terminal ++close ++curwin" -c "wincmd t"
    elif [ $1 -eq 9 ];then
      echo -c "vnew" -c "vnew" -c "windo new" -c "windo new" -c "bd 1 2 3" -c "wincmd b" -c "wincmd k" -c "wincmd =" -c "windo terminal ++close ++curwin" -c "wincmd t"
    fi
  fi
}

function vimterm(){
  if [ $# -eq 0 ];then
      exec \vim -c "terminal ++close ++curwin"
  elif [ $# -eq 1 ];then
    if [ $1 -eq 2 ];then
      exec \vim -c "vnew" -c "windo terminal ++close ++curwin" -c "wincmd t"
    elif [ $1 -eq 3 ];then
      exec \vim -c "vnew" -c "vnew" -c "windo terminal ++close ++curwin" -c "wincmd t"
    elif [ $1 -eq 4 ];then
      exec \vim -c "vnew" -c "windo new" -c "windo terminal ++close ++curwin" -c "wincmd t"
    elif [ $1 -eq 6 ];then
      exec \vim -c "new" -c "new" -c "windo vnew" -c "windo terminal ++close ++curwin" -c "wincmd t"
    elif [ $1 -eq 9 ];then
      exec \vim -c "vnew" -c "vnew" -c "windo new" -c "windo new" -c "bd 1 2 3" -c "wincmd b" -c "wincmd k" -c "wincmd =" -c "windo terminal ++close ++curwin" -c "wincmd t"
    fi
  fi
}

