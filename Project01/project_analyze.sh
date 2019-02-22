#!/bin/bash

cd ..
if [ $# -gt 0 ] ; then
    for arg in "$@" ; do
        if [ "$arg" = "todo" ] ; then
            grep -r -n "#TODO" --exclude="project_analyze.sh" --exclude="todo.log" > todo.log
            echo "Created todo.log success"
        elif [ "$arg" = "typecount" ] ; then
            echo -n 'HTML: '
            find . -type f -name \*.html | wc -l
            echo -n 'JavaScript: '
            find . -type f -name \*.js | wc -l
            echo -n 'CSS: '
            find . -type f -name \*.css | wc -l
            echo -n 'Haskell: '
            find . -type f -name \*.hs | wc -l
            echo -n 'Shell: '
            find . -type f -name \*.sh | wc -l
        fi
    done
else
    echo "No Inputs!"
fi