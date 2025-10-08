#!/bin/bash

# Installation script for fdef function and saf alias

alias saf='declare -f > ~/.bash_functions'

fdef () 
{ 
    if [[ -z "$1" ]]; then
        echo "Error: Please provide a function name (e.g. fdef myfunction)." 1>&2;
        return 1;
    fi;
    local func_name="$1";
    local temp_file=$(mktemp --suffix=.sh);
    if declare -f "$func_name" > /dev/null; then
        declare -f "$func_name" | sed -E 's/^([[:space:]]+)\1/\1/' > "$temp_file";
        echo "Editing existing function: '${func_name}'.";
    else
        echo -e "${func_name}() {\n\n  # Function logic here\n  echo \"Function ${func_name} executed.\"\n\n}" > "$temp_file";
        echo "Creating new function: '${func_name}'.";
    fi;
    local initial_hash trash;
    read initial_hash trash <<< $(md5sum "$temp_file");
    ${EDITOR:-vi} "$temp_file";
    local exit_status=$?;
    if [[ $exit_status -eq 0 ]]; then
        local final_hash;
        read final_hash trash <<< $(md5sum "$temp_file");
        if [[ "$initial_hash" == "$final_hash" ]]; then
            echo "No changes detected. Function '${func_name}' was not sourced." 1>&2;
        else
            source "$temp_file";
            echo "Function '${func_name}' successfully sourced (temporarily).";
            echo "Remember to use 'saf' (declare -f > ~/.bash_functions) to save it permanently.";
        fi;
    else
        echo "Editor exited with error. Function was not sourced." 1>&2;
        rm "$temp_file";
        return 1;
    fi;
    rm -f "$temp_file"
}
