#!/bin/bash

cd ..
if [ $# -eq 1 ] ; then
    if [ "$1" = "todo" ] ; then
        grep -r -n "#TODO" --exclude="project_analyze.sh" --exclude="todo.log" > todo.log
        echo "Created todo.log success"
    elif [ "$1" = "typecount" ] ; then
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
    elif [ "$1" = "errors" ] ; then
        > compile_errors.log
        find . -type f -regex '.*\(py\|hs\)$' -print0 | while IFS= read -d $'\0' file
        do
            if [[ $file = *.py ]] ; then
                python $file &> /dev/null
            else
                ghc -fno-code $file &> /dev/null
            fi
            if [ $? -ne 0 ] ; then 
                echo $file >> compile_errors.log
            fi
        done 
        echo 'Created compile_errors.log success'
    elif [ "$1" = "delete-temp" ] ; then
        git ls-files -z -o --exclude-standard | xargs -0 -I{} find '{}' -iname '*.tmp' | xargs rm
        echo 'Deleted untracked temporary files success'
    elif [ "$1" = "slides" ] ; then
        mkdir slides
        cd slides
        for file in $(curl -L mac1xa3.ca |
                grep href |
                sed 's/.*href="//' |
                sed 's/".*//' |
                grep -E 'Slides.*.html'); do
            curl -L -O mac1xa3.ca/$file
        done
        cd ..
    fi
else
    echo "This script must take 1 argument, see docs for usage!"
fi