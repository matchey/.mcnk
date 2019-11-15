
function upper_dir()
{
  tmplast=$OLDPWD
  if [ $# -eq 0 ];then
    cd ../
    OLDPWD=$tmplast
  else
    if [[ "$1" =~ ^[0-9]+$ ]]; then
      cd `eval printf ../"%.s" {1.."${1}"}`
      echo "$OLDPWD -> $PWD"
    else
      cd $1
    fi
  fi
}

