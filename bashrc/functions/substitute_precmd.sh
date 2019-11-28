
function substitutePreCmd()
{
  if [ $# -eq 2 ];then
    # ^$1^$2 # not work
    # !!:gs/$1/$2 # not work
  fi
}

