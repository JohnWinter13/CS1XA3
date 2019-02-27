# Project01
An interactive bash script to make your development life easier.

# Usage
`cd` into the Project01 directory

Run `./project_analyze.sh <command>`

# Features

## 1. Create a Todo log

`./project_analyze.sh todo`

Creates a todo.log file containing every line with '#TODO' in it; also displays the relative file path and line number.

Note: Will overwrite todo.log when run

## 2. Count Files

`./project_analyze.sh typecount`

Outputs a file count for HTML, Javascript, CSS, Python, Haskell and Bash Script files

## 3. Delete Temporary Files

`./project_analyze.sh delete-temp`

Deletes all files ending with .tmp and are NOT tracked by git ending in .tmp

## 4. Detect Compile Errors

`./project_analyze.sh errors`

Finds Haskell and Python files in the repo that fail to compile and puts them into compile_fail.log

Note: Will overwrite compile_fail.log when run


## 5. Download 1XA3 Slides (Custom Feature)

`./project_analyze.sh slides`

Sends a curl request to retrieve slide .html from mac1xa3.ca and puts them inside of the slides directory.
