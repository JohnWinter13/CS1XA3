#!/bin/bash

cd ..
if [ $# -gt 0 ] ; then
    for arg in "$@" ; do
        if [ "$arg" = "todo" ] ; then
            grep -r -n "#TODO" --exclude="project_analyze.sh" --exclude="todo.log" > todo.log
            echo "Created todo.log success"
        fi
    done
else
    echo "No Inputs!"
fi