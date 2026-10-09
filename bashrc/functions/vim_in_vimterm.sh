
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

function cvim(){
    if [ ! -f "CMakeLists.txt" -o ! -f "package.xml" ];then
      return
    fi
    # maxdepth=3
    # cppfiles=`find . -maxdepth $maxdepth -name "*.cpp"`
    # cppdirs=`find . -maxdepth $maxdepth -name "src"`
    # echo $cppfiles
    # echo $cppdirs
    if [ $# -eq 1 ];then
      \vim -O2 include/*/$1.h src/$1.cpp
    fi
}

function vimv(){
  if [[ "$1" == "-R" ]]; then
    cmd="\view"
    shift 1
  else
    cmd="\vim"
  fi
  if [ $# -le 1 ];then
    cmd+=" $@"
  else
    cmd+=" -O2 $1 $2"
    shift 2
    local f1 f2
    while f1=$1 f2=$2; shift 2;do
      cmd+=" -c 'New $f1 $f2'"
    done
    if [[ $(( $# & 1)) = 1 ]]; then
      cmd+=" -c 'New ${@: -1}' "
    fi
    cmd+=" -c tabnext"
  fi
  eval $cmd
}

function s:vertNTermCmd(){
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

