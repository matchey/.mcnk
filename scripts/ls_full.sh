#!/bin/bash

for arg in "${@:-.}"; do
  if [ -d "$arg" ]; then
    realpath -s "$arg"/*
  else
    realpath -s "$arg"
  fi
done

