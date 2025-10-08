#!/bin/bash

# Installation script for fdef function, sal and saf aliases

# Ensure this script is sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this script must be sourced, not executed. Use: source fdef.sh" >&2
  exit 1
fi

alias sal &> /dev/null && { echo "Alias 'sal' already exists. Will not overwrite it. Aborted installation." >&2; return 1; }
alias saf &> /dev/null && { echo "Alias 'saf' already exists. Will not overwrite it. Aborted installation." >&2; return 1; }
declare -f fdef &> /dev/null && { echo "Function 'fdef' already exists. Will not overwrite it. Aborted installation." >&2; return 1; }
declare -f uninstall_fdef &> /dev/null && { echo "Function 'uninstall_fdef' already exists. Will not overwrite it. Aborted installation." >&2; return 1; }

alias sal='alias > ~/.bash_aliases'
alias saf='declare -f > ~/.bash_functions'
echo "Defined aliases: sal, saf."
alias sal
alias saf

# Add source statements to .bashrc if not already present
if [[ -f ~/.bashrc ]]; then

  if ! grep -q "\.bash_functions" ~/.bashrc; then
    echo '[ -f ~/.bash_functions ] && source ~/.bash_functions # Added by fdef installer' >> ~/.bashrc
    echo "Auto-load '~/.bash_functions' statement added to ~/.bashrc."
  fi

  if ! grep -q "\.bash_aliases" ~/.bashrc; then
    echo '[ -f ~/.bash_aliases ] && source ~/.bash_aliases # Added by fdef installer' >> ~/.bashrc
    echo "Auto-load '~/.bash_aliases' statement added to ~/.bashrc."
  fi

fi

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
    local initial_hash _;
    read initial_hash _ <<< $(md5sum "$temp_file");
    ${EDITOR:-vi} "$temp_file";
    local final_hash;
    read final_hash _ <<< $(md5sum "$temp_file");
    if [[ "$initial_hash" == "$final_hash" ]]; then
        echo "No changes detected. Function '${func_name}' was not sourced." 1>&2;
    else
        source "$temp_file";
        local funcname
        read funcname _ < "$temp_file"
        echo "Function '${funcname}' successfully sourced (temporarily).";
        echo "Remember to use 'saf' (declare -f > ~/.bash_functions) to save it permanently.";
    fi;
    rm -f "$temp_file"
}
echo "Defined function fdef."

_fdef_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    readarray -t COMPREPLY < <(compgen -A function -- "$cur")
}
complete -F _fdef_completion fdef
echo "Bash completion for fdef enabled."

uninstall_fdef() {
  echo "Uninstalling fdef, sal, and saf..."

  # Remove aliases and function definitions from current session
  unalias sal 2>/dev/null
  unalias saf 2>/dev/null
  unset -f fdef 2>/dev/null
  unset -f uninstall_fdef 2>/dev/null
  unset -f _fdef_completion 2>/dev/null

  # Remove fdef completions from current session
  complete -r fdef 2>/dev/null

  # Remove fdef-related definitions from ~/.bash_aliases
  if [[ -f ~/.bash_aliases ]]; then
    cp ~/.bash_aliases ~/.bash_aliases.bak
    alias > ~/.bash_aliases
    echo "Removed 'sal' and 'saf' from ~/.bash_aliases (backup: ~/.bash_aliases.bak)."
  fi

  # Remove fdef-related definitions from ~/.bash_functions
  if [[ -f ~/.bash_functions ]]; then
    cp ~/.bash_functions ~/.bash_functions.bak
    declare -f > ~/.bash_functions
    echo "Removed 'fdef', 'uninstall_fdef', and '_fdef_completion' from ~/.bash_functions (backup: ~/.bash_functions.bak)."
  fi

  # Remove autoload lines from .bashrc (only if present)
  if [[ -f ~/.bashrc ]]; then
    if grep -q 'Added by fdef installer' ~/.bashrc; then
      sed -i.bak '/Added by fdef installer/d' ~/.bashrc
      echo "Removed autoload entries from ~/.bashrc (backup saved as ~/.bashrc.bak)."
    else
      echo "No autoload entries found in ~/.bashrc - nothing to remove."
    fi
  fi

  # Offer to delete the saved alias and function files
  for file in ~/.bash_aliases ~/.bash_functions; do
    if [[ -f "$file" ]]; then
      read -p "Delete $file? [y/N] " reply
      [[ "$reply" =~ ^[Yy]$ ]] && rm -f "$file" && echo "Deleted $file."
    fi
  done

  echo "Uninstallation completed."
}
echo "Defined function uninstall_fdef."
