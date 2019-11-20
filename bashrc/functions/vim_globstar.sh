
function vim_globstar()
{
  # shopt -s globstar
  # \vim **/$1
  # shopt -u globstar
  # find . -maxdepth 10 -name "$1" -type f >& /dev/null
  filename=`locate $1 | grep "^$PWD" | head -1`
  \vim ${filename#$PWD/}
}

