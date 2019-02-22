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
        elif [ "$arg" = "errors" ] ; then
            > compile_errors.log
            find . -type f -regex '.*\(py\|hs\)$' -print0 | while IFS= read -d $'\0' file
            do
                if [[ $file = *.py ]] ; then
                    python $file &> /dev/null
                else
                    ghc $file &> /dev/null
                fi
                if [ $? -ne 0 ] ; then 
                    echo $file >> compile_errors.log
                fi
            done 
            echo 'Created compile_errors.log success'
        fi
    done
else
    echo "No Inputs!"
fi