#!/usr/bin/env bash


if [[ $# -eq 2 ]]; then
    on_yes=$1
    on_no=$2
else
    echo "Error: Please provide a callback function, command or script file as an argument."
    exit 1
fi


exit 0
