#!/bin/bash

# if this script gets error at unexpected lines, exit anyways
set -e

# usage 
usage() {
  cat << EOS >&2

USAGE:
  sh datalog_compress.sh [options]
OPTIONS:
  -i input_dir   Argument is required. Directory which stores datalog (datalog is directory which contains multiple rosbags). The default argument is set as './'.
  -o output_dir  Argument is required. Directory to save compressed data. The default argument is set as same as input_dir.
  -s search_str  Argument is required. Search target directories which contains the 'argument' string.
  -t             Use tar (tgz) to compress files.
  -h             Show this help message.
EOS
}

invalid() {
  usage 1>&2
  echo "$@" 1>&2
  exit 1
}

IN_DIR=""
while getopts "hts:i:o:" OPT
do
  case $OPT in
    h)
      usage
      exit 0
      ;;
    t)
      if [ -n "$USE_TAR" ]; then
        invalid "Duplicated 'option-t'."
        exit 1
      fi
      echo Use Tar
      USE_TAR=TRUE
      ;;
    s)
      if [ -z "$OPTARG" ]; then
        invalid "'option-s' requires argument."
        exit 1
      fi
      SEARCH_STR="$OPTARG"
      echo "Adapt compression for directories includes : ${SEARCH_STR}" 
      ;;
    i)
      if [ -z "$OPTARG" ]; then
        invalid "'option-i' requires argument."
        exit 1
      fi
      IN_DIR="$OPTARG"
      ;;
    o)
      if [ -z "$OPTARG" ]; then
        invalid "'option-o' requires argument."
        exit 1
      fi
      OUT_DIR="$OPTARG"
      ;;
    *)
      usage
      exit 0
  esac
done

# check arguments
if [ -z "$IN_DIR" ]; then
  echo "You did not insert input directory, set defalt as './'"
  IN_DIR="./"
fi

if [ ! -d "$IN_DIR" ]; then
    echo "Input directory: $IN_DIR does not exist. "
    exit 1
fi

# setup host directories
HOST_IN_DIR=$(realpath $IN_DIR)
HOST_OUT_DIR=$(realpath ${OUT_DIR-$IN_DIR})

if [ ! -d "$HOST_OUT_DIR" ]; then
    mkdir -p $HOST_OUT_DIR
fi

echo "input directory  : $HOST_IN_DIR"
echo "output directory : $HOST_OUT_DIR"

# configurations
# Actually we can use any container image which includes ROS. We just
# use toolkit image as we can download from internal server.
CONTAINER_IMAGE="snserv21.sm.sony.co.jp:5000/bdkr-advance/stork/sdk:develop-kit.20220209_01"
CONTAINER_IN_DIR="/mnt/in"
CONTAINER_OUT_DIR="/mnt/out"
CONTAINER_ROS_VERSION="melodic"

COMPRESS_CPU_NUM=$(grep -c ^processor /proc/cpuinfo)
COMPRESS_ALGO="--lz4"

# execute rosbag compress in container
for dirname in `cd $HOST_IN_DIR; ls -d *${SEARCH_STR}*/`; do
    IN_DIR_NAME="$HOST_IN_DIR/${dirname%/}"
    OUT_DIR_NAME="$HOST_IN_DIR/${dirname%/}_lz4"

    # skip if compressed target is existed
    if [ ! "${USE_TAR}" ]; then
      if [ -d "$HOST_OUT_DIR/${dirname%/}_lz4" -o -n "$(echo $dirname | grep _lz4)" ]; then
          echo "Skipped: $HOST_OUT_DIR/${dirname%/}"
      else
          # make tmp dir to store compressed rosbag if not existed. 
          if [ ! -d "$OUT_DIR_NAME" ]; then
              mkdir -p $OUT_DIR_NAME
          fi
          # compress rosbag
          docker run -it --rm \
              -u $(id -u):$(id -g) --entrypoint /bin/bash \
              -v $IN_DIR_NAME:$CONTAINER_IN_DIR -v $OUT_DIR_NAME:$CONTAINER_OUT_DIR $CONTAINER_IMAGE \
              -c "source /opt/ros/${CONTAINER_ROS_VERSION}/setup.bash;
                  ls $CONTAINER_IN_DIR/*.bag |
                  xargs -P $COMPRESS_CPU_NUM -n 1 rosbag compress $COMPRESS_ALGO --output-dir=$CONTAINER_OUT_DIR"
          if [ $IN_DIR_NAME != $HOST_OUT_DIR/${dirname%/} ]; then
              mv ${IN_DIR_NAME}_lz4 $HOST_OUT_DIR
          fi
      fi
    else # if -t option is enabled, use tar (tgz)
      if [ -e "$HOST_OUT_DIR/${dirname%/}.tar" -o -n "$(echo $dirname | grep _lz4)"  ]; then
          # skip if target.tar is existed
          echo "Skipped: $HOST_OUT_DIR${dirname%/}"
      else
          # compress dir with tar
          cd $HOST_IN_DIR; tar -zcvf "${dirname%/}".tgz "${dirname%/}"
          # mv to out dir
          if [ $IN_DIR_NAME != $HOST_OUT_DIR/${dirname%/} ]; then
              mv $IN_DIR_NAME.tgz $HOST_OUT_DIR
          fi
      fi
    fi
    echo "Done."
done
