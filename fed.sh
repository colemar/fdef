#!/bin/bash

# Installation script for fed function, sal and saf aliases

# Ensure this script is sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Error: this script must be sourced, not executed. Use: source fed.sh" >&2
  exit 1
fi

for _name in sal saf _check_fed_name fed _fed_completion uninstall_fed; do
  if type $_name &>/dev/null; then
    echo "Error: cannot define '$_name' because it exists already as type '$(type -t $_name)'" >&2
    return 1
  fi
done

sal() {
  local file=~/.bash_aliases

  # If file exists and has been modified by another session, make a backup
  if (( $(stat -c %Y "$file") > ${_last_sal:-0} )) &>/dev/null; then
    local bfile="${file}.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$file" "$bfile"
    echo "Backup created: $bfile"
  fi

  # Save aliases and add timestamp initialization
  local temp_file=$(mktemp)
  alias > "$temp_file"
  echo '_last_sal=$(date +%s)' >> "$temp_file"
  _last_sal=$(date +%s)
  if diff "$temp_file" "$file" &>/dev/null; then
    echo "There are no changes since the last save."
    return 0
  fi
  mv "$temp_file" "$file"
  echo "Aliases saved to $file"
}

saf() {
  local file=~/.bash_functions

  # If file exists and has been modified by another session, make a backup
  if (( $(stat -c %Y "$file") > ${_last_saf:-0} )) &>/dev/null; then
    local bfile="${file}.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$file" "$bfile"
    echo "Backup created: $bfile"
  fi

  # Save functions and add timestamp initialization
  local temp_file=$(mktemp)
  declare -f > "$temp_file"
  echo '_last_saf=$(date +%s)' >> "$temp_file"
  _last_saf=$(date +%s)
  if diff "$temp_file" "$file" &>/dev/null; then
    echo "There are no changes since the last save."
    return 0
  fi
  mv "$temp_file" "$file"
  echo "Functions saved to $file"
}

echo "Defined functions: sal, saf."

# Add source statements to .bashrc if not already present
if [[ -f ~/.bashrc ]]; then

  cp ~/.bashrc ~/.bashrc.bak
  echo "Made backup of ~/.bashrc as ~/.bashrc.bak."

  if ! grep -q "\.bash_functions" ~/.bashrc; then
    echo '[[ -f ~/.bash_functions ]] && source ~/.bash_functions # Added by fed installer' >> ~/.bashrc
    echo "Auto-load '~/.bash_functions' statement added to ~/.bashrc."
  fi

  if ! grep -q "\.bash_aliases" ~/.bashrc; then
    echo '[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases # Added by fed installer' >> ~/.bashrc
    echo "Auto-load '~/.bash_aliases' statement added to ~/.bashrc."
  fi

fi

# Helper function to check if a word is a valid function name
_check_fed_name() {
  # a word is a valid function name if and only if it is a valid variable name
  local "$1"="" &>/dev/null || return 1
}

fed () {
  if [[ -z "$1" ]]; then
    echo "Error: Please provide a function name (e.g. fed myfunction)." >&2
    return 1
  fi
  local func_name="$1"
  if ! _check_fed_name "$func_name"; then
    echo "Error: invalid function name '$func_name'" >&2
    return 1
  fi
  local t=$(type -t "$func_name")
  if [[ ! "$t" == "" && ! "$t" == function ]]; then
    echo "Error: '$func_name' exists and is of type '$t'" >&2
    return 1
  fi
  local temp_file=$(mktemp --suffix=.sh)
  if declare -f "$func_name" > /dev/null; then
    # Extract function definition from session and halve the indentation.
    # The regex ^([[:space:]]+)\1 -> \1 matches two identical indentation blocks and keeps one.
    declare -f "$func_name" | sed -E 's/^([[:space:]]+)\1/\1/' > "$temp_file"
    echo "Editing existing function: '${func_name}'."
  else
    echo -e "${func_name}()\n{\n\n  # Function logic here\n  echo \"Function ${func_name} executed.\"\n\n}" > "$temp_file"
    echo "Creating new function: '${func_name}'."
  fi
  local initial_hash final_hash answer x
  while true; do
    read -r initial_hash x <<< $(md5sum "$temp_file")
    ${EDITOR:-vi} "$temp_file"
    local final_hash
    read -r final_hash x <<< $(md5sum "$temp_file")
    if [[ "$initial_hash" == "$final_hash" ]]; then
      echo "No changes detected. Function '${func_name}' was not sourced." >&2
      read -r -p "Try again? [Y/n]" answer
      [[ "$answer" == [nN] ]] && break || continue
    fi
    read -r func_name < "$temp_file"
    func_name=${func_name%%(*}; func_name=${func_name##*([[:space:]])}; func_name=${func_name%%*([[:space:]])}
    # If func_name is valid, source $temp_file and go on
    if ! _check_fed_name "$func_name"; then
      echo "Error: invalid function name '${func_name}'" >&2
      read -r -p "Try again? [Y/n]" answer
      [[ "$answer" == [nN] ]] && break || continue
    fi
    t=$(type -t "$func_name")
    if [[ ! "$t" == "" && ! "$t" == function ]]; then
      echo "Error: '$func_name' exists and is of type '$t'" >&2
      read -r -p "Try again? [Y/n]" answer
      [[ "$answer" == [nN] ]] && break || continue
    fi
    if ! source "$temp_file"; then
      echo "Error: sourcing failed" >&2
      read -r -p "Try again? [Y/n]" answer
      [[ "$answer" == [nN] ]] && break || continue
    fi
    echo "Function '${func_name}' successfully sourced (temporarily)."
    echo "Remember to use 'saf' (declare -f > ~/.bash_functions) to save it permanently."
    break
  done
  rm -f "$temp_file"
}
echo "Defined function fed."

# Save completion to standard location
mkdir -p ~/.local/share/bash-completion/completions/
cat > ~/.local/share/bash-completion/completions/fed << 'EOF'
# Bash completion for fed
_fed_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  readarray -t COMPREPLY < <(compgen -A function -- "$cur")
}
complete -F _fed_completion fed
EOF

# Load completion for current session
source ~/.local/share/bash-completion/completions/fed
echo "Bash completion for fed enabled."

# Add fallback only if bash-completion is not available
if [[ -z "$BASH_COMPLETION_VERSINFO" ]] && ! grep -q "completions/fed" ~/.bashrc; then
  echo '[[ -f ~/.local/share/bash-completion/completions/fed ]] && source ~/.local/share/bash-completion/completions/fed # Added by fed installer' >> ~/.bashrc
  echo "Added fallback completion loader to ~/.bashrc (bash-completion not detected)."
fi

uninstall_fed() {
  echo "Undefining sal, saf, fed, uninstall_fed ..."

  # Remove fed completions from current session
  complete -r fed 2>/dev/null

  # Remove function definitions from current session
  unset -f sal saf _check_fed_name fed _fed_completion uninstall_fed 2>/dev/null

  # Remove timestamp variables
  unset _last_sal _last_saf 2>/dev/null

  # Remove fed-related definitions from ~/.bash_functions
  local file=~/.bash_functions
  if [[ -f $file ]]; then
    local bfile=$file.backup-$(date +%Y%m%d-%H%M%S)
    cp $file $bfile
    declare -f > $file
    echo "Removed 'sal', 'saf', 'fed' and 'uninstall_fed' from $file (backup: $bfile)."
  fi

  # Remove completion file
  if [[ -f ~/.local/share/bash-completion/completions/fed ]]; then
    rm -f ~/.local/share/bash-completion/completions/fed
    echo "Removed ~/.local/share/bash-completion/completions/fed"
  fi

  # Remove autoload lines from .bashrc (only if present)
  if [[ -f ~/.bashrc ]]; then
    if grep -q 'Added by fed installer' ~/.bashrc; then
      sed -i '/Added by fed installer/d' ~/.bashrc
      echo "Removed autoload entries from ~/.bashrc."
    else
      echo "No autoload entries found in ~/.bashrc - nothing to remove."
    fi
  fi

  echo "Uninstallation completed."
}
echo "Defined function uninstall_fed."

# Save tools permanently
echo "Saving installation..."
saf

echo "Installation completed."
