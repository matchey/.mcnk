#!/bin/bash

find . -name "* *" | sed -e 's/.*/"&"/; p; s/ /_/g' | xargs -n 2 mv

