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
  local needs_backup=false
  
  # Check if file exists and has been modified by another session
  if [[ -f "$file" ]]; then
    local file_mtime=$(stat -c %Y "$file")
    # Use >= instead of > for safety: protects against modifications in the same second
    if [[ -z "$_last_sal" ]] || (( file_mtime >= _last_sal )); then
      needs_backup=true
    fi
  fi
  
  # Backup if necessary
  if [[ "$needs_backup" == true ]]; then
    cp "$file" "${file}.backup-$(date +%Y%m%d-%H%M%S)"
    echo "Backup created: ${file}.backup-$(date +%Y%m%d-%H%M%S)"
  fi
  
  # Set timestamp first to detect concurrent modifications correctly
  _last_sal=$(date +%s)
  # Save aliases and add timestamp initialization
  alias > "$file"
  echo '_last_sal=$(date +%s)' >> "$file"
  echo "Aliases saved to $file"
}

saf() {
  local file=~/.bash_functions
  local needs_backup=false
  
  # Check if file exists and has been modified by another session
  if [[ -f "$file" ]]; then
    local file_mtime=$(stat -c %Y "$file")
    # Use >= instead of > for safety: protects against modifications in the same second
    if [[ -z "$_last_saf" ]] || (( file_mtime >= _last_saf )); then
      needs_backup=true
    fi
  fi
  
  # Backup if necessary
  if [[ "$needs_backup" == true ]]; then
    cp "$file" "${file}.backup-$(date +%Y%m%d-%H%M%S)"
    echo "Backup created: ${file}.backup-$(date +%Y%m%d-%H%M%S)"
  fi
  
  # Set timestamp first to detect concurrent modifications correctly
  _last_saf=$(date +%s)
  # Save functions and add timestamp initialization
  declare -f > "$file"
  echo '_last_saf=$(date +%s)' >> "$file"
  echo "Functions saved to $file"
}

echo "Defined functions: sal, saf."

# Add source statements to .bashrc if not already present
if [[ -f ~/.bashrc ]]; then

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
  if ! [[ "$t" == "" || "$t" == function ]]; then
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
  local initial_hash _
  read -r initial_hash _ <<< $(md5sum "$temp_file")
  ${EDITOR:-vi} "$temp_file"
  local final_hash
  read -r final_hash _ <<< $(md5sum "$temp_file")
  if [[ "$initial_hash" == "$final_hash" ]]; then
    echo "No changes detected. Function '${func_name}' was not sourced." >&2
  else
    read -r func_name < "$temp_file"
    func_name=${func_name%%(*}; func_name=${func_name##*([[:space:]])}; func_name=${func_name%%*([[:space:]])}
    if source "$temp_file"; then
      echo "Function '${func_name}' successfully sourced (temporarily)."
      echo "Remember to use 'saf' (declare -f > ~/.bash_functions) to save it permanently."
    else
      echo "Error: sourcing failed" >&2
    fi
  fi
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
  if [[ -f ~/.bash_functions ]]; then
    cp ~/.bash_functions ~/.bash_functions.bak
    declare -f > ~/.bash_functions
    echo "Removed 'sal', 'saf', 'fed' and 'uninstall_fed' from ~/.bash_functions (backup: ~/.bash_functions.bak)."
  fi

  # Remove completion file
  if [[ -f ~/.local/share/bash-completion/completions/fed ]]; then
    rm -f ~/.local/share/bash-completion/completions/fed
    echo "Removed ~/.local/share/bash-completion/completions/fed"
  fi

  # Remove autoload lines from .bashrc (only if present)
  if [[ -f ~/.bashrc ]]; then
    if grep -q 'Added by fed installer' ~/.bashrc; then
      sed -i.bak '/Added by fed installer/d' ~/.bashrc
      echo "Removed autoload entries from ~/.bashrc (backup: ~/.bashrc.bak)."
    else
      echo "No autoload entries found in ~/.bashrc - nothing to remove."
    fi
  fi

  echo ""
  echo "Note: ~/.bash_aliases and ~/.bash_functions have been left intact."
  echo "You can delete them manually if needed."

  echo "Uninstallation completed."
}
echo "Defined function uninstall_fed."

# Save tools permanently
echo "Saving installation..."
saf
sal

echo "Installation completed."
