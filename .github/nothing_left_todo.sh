#!/usr/bin/env bash

check() {
  TARGET=${1}
  if grep --recursive -Iie "\\btodo\\b" ${TARGET}
    then
      echo "There are remaining items TODO"
      exit 1;
    else
      echo "${TARGET} OK"
  fi
}

# Check the specified directories
check global
check models
