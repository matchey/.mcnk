
intersection()
{
  printf '%s\n' $@ | sort | uniq -d
}

find_h_cpp_list()
{
  function find_h_cpp()
  {
    cppfile=`find ${PWD} -maxdepth 10 -name "${1}.cc" -or -name "${1}.c" -or -name "${1}.cpp" -type f`
    if [ -z "$cpplist" ]; then
      return
    fi

    hfile=`find ${PWD} -maxdepth 10 -name "${1}.h" -or -name "${1}.hpp" -type f`
    if [ -z "$hlist" ]; then
      return
    fi

    echo ${hfile}
    echo ${cppfile}
  }

  hcppfiles=()
  for f in "${@}"
  do
    hcppfiles+=(`find_h_cpp $f`)
  done

  hcppfiles="${hcppfiles[*]}"
}

_find_h_cpp()
{
  cpplist=`find . -maxdepth 10 -name "*.cc" -or -name "*.c" -or -name "*.cpp" -type f`
  if [ -z "$cpplist" ]; then
    return
  fi

  hlist=`find . -maxdepth 10 -name "*.h" -or -name "*.hpp" -type f`
  if [ -z "$hlist" ]; then
    return
  fi

  cppbase=`echo ${cpplist[@]} | xargs -n1 basename`
  cppbase=${cppbase[@]//.cpp/}
  cppbase=${cppbase[@]//.cc/}
  hbase=`echo ${hlist[@]} | xargs -n1 basename`
  hbase=${hbase[@]//.hpp/}

  inter=(`intersection "${cppbase[@]//.c/}" "${hbase[@]//.h/}"`)

  COMPREPLY=( $(compgen -W "${inter[*]}" ${COMP_WORDS[COMP_CWORD]} ) )
}
complete -F _find_h_cpp hcpp

