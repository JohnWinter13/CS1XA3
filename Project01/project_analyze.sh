#!/bin/bash

cd ..
if [ $# -eq 1 ] ; then
    if [ "$1" = "todo" ] ; then
        #look for #TODO, but exclude the todo log itself and this file and write to the log
        grep -r -n "#TODO" --exclude="project_analyze.sh" --exclude="todo.log" > todo.log
        echo "Created todo.log success"
    elif [ "$1" = "typecount" ] ; then
        #count files ending with certain extensions
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
        #create log file, overwrite if it exists
        > compile_errors.log
        #look for .py and .hs files
        find . -type f -regex '.*\(py\|hs\)$' -print0 | while IFS= read -d $'\0' file
        do
            #select the correct compiler
            if [[ $file = *.py ]] ; then
                python $file &> /dev/null
            else
                ghc -fno-code $file &> /dev/null #flag is needed to not create extra files
            fi
            #check exit code, if it's not 0 => failure
            if [ $? -ne 0 ] ; then 
                echo $file >> compile_errors.log
            fi
        done 
        echo 'Created compile_errors.log success'
    elif [ "$1" = "delete-temp" ] ; then
        #look for files untracked by git and delete those ending in .tmp
        git ls-files -z -o --exclude-standard | xargs -0 -I{} find '{}' -iname '*.tmp' | xargs rm
        echo 'Deleted untracked temporary files success'
    elif [ "$1" = "slides" ] ; then
        mkdir slides
        cd slides
        #make a curl request to mac1xa3.ca and retrieve HTMl
        #go through it and look for links, denoted by href 
        #if we end up with a .html file that has Slides in the file path,
        #then it is a lecture or lab slide (according to the website's)
        #structure at current date, since all the slides are located at 
        #mac1xa3.ca/Slides
        for file in $(curl -L mac1xa3.ca |
                grep href |
                sed 's/.*href="//' |
                sed 's/".*//' |
                grep -E 'Slides.*.html'); do
            curl -L -O mac1xa3.ca/$file # -O will write the $file in the slides directory
        done
        cd ..
    fi
else
    echo "This script must take 1 argument, see docs for usage!"
fi