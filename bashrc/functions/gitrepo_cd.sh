#!/bin/bash

ghq_cd() {
  local dir
  dir=$(ghq list -p | fzf) && cd "$dir"
}

