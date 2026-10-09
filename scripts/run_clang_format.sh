#!/bin/bash -e

CMD=$(basename $0)

CLANG_FORMAT="clang-format-14"    # clang-format-14 is default version on Ubuntu 22.04.
CLANG_FORMAT_FILE_NAME='.clang-format'
CLANG_FORMAT_FILE_PATH=`find_parent ${CLANG_FORMAT_FILE_NAME}`

if [ $# -ne 1 ]; then
    echo "./${CMD} [target path to apply clang-format]"

    exit 1
fi

target_path=$1

if [ -z "${CLANG_FORMAT_FILE_PATH}" ]; then
  echo "format file [${CLANG_FORMAT_FILE_PATH}] does not exist" 1>&2
  exit 1
fi

# error check
if ! type "${CLANG_FORMAT}" > /dev/null 2>&1 ; then
    echo "${CLANG_FORMAT} not exist" 1>&2
    exit 1
fi
if [ ! -e ${target_path} ]; then
    echo "${target_path} not exist" 1>&2
    exit 1
fi

cd ${target_path}
find ./ -name '*.h' \
     -o -name '*.hpp' \
     -o -name '*.c' \
     -o -name '*.cpp' \
     -o -name '*.cc' \
    | xargs ${CLANG_FORMAT} -i -style=file:"${CLANG_FORMAT_FILE_PATH}" --verbose
