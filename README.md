# fed - Bash Function Editor

![Made with Bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)

A simple and practical system for creating and editing bash functions interactively.

## 📑 Table of Contents

- [🚀 Installing](#-installing)
- [🧹 Uninstalling](#-uninstalling)
- [📖 What it provides](#-what-it-provides)
- [💡 Typical Workflow](#-typical-workflow)
- [🔧 Editing existing functions](#-editing-existing-functions)
- [🚫 Forbidden names](#-forbidden-names)
- [⚙️ Configuration](#config)
- [📋 Features](#-features)
- [🛡️ Safety and Best Practices](#sabp)
- [⚠️ Limitations](#limit)
- [🤝 Contributing](#-contributing)
- [👤 Author](#-author)

## 🚀 Installing

Copy and paste this command into your terminal:

```bash
source <(curl -sL https://raw.githubusercontent.com/colemar/fed/main/fed.sh)
```

This will install and save `sal`, `saf`, `fed`, and `uninstall_fed` permanently. It will also save bash completion for `fed` to `~/.local/share/bash-completion/completions/fed` and modify your `~/.bashrc` file to automatically load your functions, aliases and completions in future sessions. A backup of the file is created before this operation.

## 🧹 Uninstalling

Copy and paste this command into your terminal:

```bash
uninstall_fed
```

This will remove functions `sal`, `saf`, `fed`, `uninstall_fed`, and `_fed_completion`, the completion file `~/.local/share/bash-completion/completions/fed`, and auto-load entries from `~/.bashrc`.

Your custom aliases in `~/.bash_aliases` will be **left intact**.

Your `~/.bash_functions` file will be safely **overwritten** with a new snapshot that excludes the `fed` functions but **preserves all your other custom functions**. A backup of the file is created before this operation.

You can reinstall at any time as explained in the [Installing](#-installing) section.

## 📖 What it provides

### `fed` - Function Edit

Command to create or modify bash functions interactively.

**Syntax:**

```bash
fed function_name
```

**Behavior:**

- If an *alias*, a *keyword*, a *builtin*, or an executable *file* named `function_name` **already exists**: shows an error message and stops
- If the function **doesn't exist**: creates a basic template and opens the editor
- If the function **already exists**: loads it into the editor for modification
- After saving from editor, loads the (possibly renamed) function into the current shell (only for the current session)
- Automatically detects if changes were made (via MD5 hash). Checks if the function name is valid and not already used.
- Tab completion suggests existing function names when typing `fed <TAB>`

### `sal` - Save ALiases

Function to save all currently defined aliases.

**Syntax:**

```bash
sal
```

**Effect:**

```bash
# Equivalent to:
alias > ~/.bash_aliases
# Except that it makes a timestamped backup if required
```

Takes a *snapshot* of all aliases currently defined in the shell and saves it to `~/.bash_aliases`, making them permanent across sessions.

If the file is newer than the last use of `sal`, a timestamped backup is made before overwriting it.

### `saf` - Save All Functions

Function to save all currently defined bash functions.

**Syntax:**

```bash
saf
```

**Effect:**

```bash
# Equivalent to:
declare -f > ~/.bash_functions
# Except that it makes a timestamped backup if required
```

Takes a *snapshot* of all currently defined bash functions and saves it to `~/.bash_functions`, making them permanent across sessions.

If the file is newer than the last use of `saf`, a timestamped backup is made before overwriting it.

## 💡 Typical Workflow

### 1. Create a new function

```bash
$ fed mytest
Creating new function: 'mytest'.
# Opens the editor with a template
```

Default template:

```bash
mytest()
{

  # Function logic here
  echo "Function mytest executed."

}
```

### 2. Edit and save

Modify the function in the editor, save and close. You'll see:

```bash
Function 'mytest' successfully sourced (temporarily).
Remember to use 'saf' (declare -f > ~/.bash_functions) to save it permanently.
```

### 3. Test the function

```bash
$ mytest
Function mytest executed.
```

### 4. Save permanently

When you're satisfied:

```bash
$ saf
```

Now the function is saved in `~/.bash_functions`.

## 🔧 Editing existing functions

```bash
$ fed oldfunc
Editing existing function: 'oldfunc'.
# Opens the editor with the current definition
```

Modify the function in the editor, save and close. You'll see:

```bash
Function 'oldfunc' successfully sourced (temporarily).
Remember to use 'saf' (declare -f > ~/.bash_functions) to save it permanently.
```

While inside the editor you can also optionally rename the function by modifying its signature. This will create a new function with the chosen name, based on the old function, leaving the old function unmodified.

If you change the name in the signature to `newfunc`, you'll see:

```bash
Function 'newfunc' successfully sourced (temporarily).
Remember to use 'saf' (declare -f > ~/.bash_functions) to save it permanently.
```

If you exit the editor without changes:

```bash
No changes detected. Function 'oldfunc' was not sourced.
```

## 🚫 Forbidden names

If the given name is **bad** (invalid or already an *alias*, a *keyword*, a *builtin*, or an executable *file*), an error message is printed and the workflow is stopped:

```bash
$ fed "my func"
Error: invalid function name 'my func'

$ fed help
Error: 'help' exists and is of type 'builtin'

$ fed sed
Error: 'sed' exists and is of type 'file'

$ fed case
Error: 'case' exists and is of type 'keyword'
```

If the name in the function signature is changed to a **bad** one before exiting the editor, an error is displayed, and the user can choose to **return** to the editor:

```bash
$ fed helper
Creating new function: 'helper'.
Error: 'help' exists and is of type 'builtin'
Try again? [Y/n]
```

This also occurs if **no changes** were made, or if **syntax errors** prevent the function definition from being sourced.

## ⚙️ <a name="config"></a>Configuration

### Default editor

`fed` uses the editor specified in the `$EDITOR` environment variable. If not set, it uses `vi` as a fallback.

To set your preferred editor, add to your `~/.bashrc`:

```bash
export EDITOR=nano    # or vim, emacs, code, etc.
```

## 📋 Features

- ✅ **No external dependencies** (just standard bash)
- ✅ **Safety**: doesn't overwrite anything automatically
- ✅ **Clear feedback**: informative messages at every step
- ✅ **Change detection**: avoids unnecessary sourcing
- ✅ **Automatic cleanup**: removes temporary files
- ✅ **Smart template**: creates ready-to-use functions
- ✅ **Tab completion**: suggests function names while typing
- ✅ **Multi-session protection**: automatic backups prevent data loss

## 🛡️ <a name="sabp"></a>Safety and Best Practices

- Functions are loaded **temporarily** into the current shell
- Nothing is written to permanent files until you explicitly use `saf`
- Temporary files are always removed after use
- You can test functions before saving them permanently

## 📝 Practical Examples

### Create a function for quick navigation

```bash
$ fed goto
# In the editor:
goto() {
  case "$1" in
    projects) cd ~/projects ;;
    docs) cd ~/Documents ;;
    *) echo "Unknown location: $1" ;;
  esac
}
```

### Create a function with parameters

```bash
$ fed backup
# In the editor:
backup() {
  local source="$1"
  local dest="${2:-~/backups}"
  cp -r "$source" "$dest/$(basename "$source")-$(date +%Y%m%d)"
  echo "Backup completed: $dest"
}
```

## ⚠️ <a name="limit"></a>Limitations

- The `sal` and `saf` commands work by taking a full *snapshot* of the current shell state (aliases and functions). **They are not incremental tools** – each snapshot completely replaces the corresponding file.

- **Multi-session safety**: `sal` and `saf` include automatic backup protection. When you run `sal` or `saf`, if the target file (`~/.bash_aliases` or `~/.bash_functions`) has been modified by another session since your last save, a timestamped backup is automatically created before overwriting. This protects against accidental loss of changes made in other terminal sessions.
  
  Example: If another session modifies `~/.bash_functions` and you run `saf`, you'll see:
  
  ```
  Backup created: ~/.bash_functions.backup-20250119-143022
  Functions saved to ~/.bash_functions
  ```

- If you manually edit `~/.bash_aliases` or `~/.bash_functions`, the next execution of `sal` or `saf` will create a timestamped backup before overwriting the files. However, it's recommended to use `fed` for functions and define aliases interactively in the shell, then use `sal`/`saf` to save them.

- **Formatting is not preserved**: When editing a function, bash reformats the code automatically due to how functions are stored internally.  This means:
  
  - All comments (`#`) are stripped out
  
  - Indentation is standardized
  
  - Empty lines and custom spacing are removed

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to open an issue or pull request.

## 👤 Author

**colemar**

- GitHub: [@colemar](https://github.com/colemar)

---

⭐ If you find this project useful, consider giving it a star on GitHub!
