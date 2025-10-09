# fed - Bash Function Editor

![Made with Bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)

A simple and practical system for creating and editing bash functions interactively.

## 📑 Table of Contents

- [🚀 Installing](#-installing)
- [🧹 Uninstall](#-uninstall)
- [📖 What it provides](#-what-it-provides)
- [💡 Typical Workflow](#-typical-workflow)
- [🔧 Editing existing functions](#-editing-existing-functions)
- [🚫 Forbidden names](#-forbidden-names)
- [⚙️ Configuration](#config)
- [📋 Features](#-features)
- [🛡️ Safety and Best Practices](#sabp)
- [⚠️ Limitations](#-limitations)
- [🤝 Contributing](#-contributing)
- [👤 Author](#-author)

## 🚀 Installing

#### Step 1: Run the installer

Copy and paste this command into your terminal:

```bash
source <(curl -sL https://raw.githubusercontent.com/colemar/fed/main/fed.sh)
```

This will load aliases `sal` `saf` and functions `fed` `uninstall_fed` into your current session. It will also enable bash completion for `fed` and modify your `~/.bashrc` file to automatically load your functions and aliases in future sessions.

#### Step 2: Save the tools for future sessions

After running the installer, the new tools are available, but only for the current session. Run these two commands to save them permanently:

```bash
# Saves all the defined functions - including 'fed' and 'uninstall_fed' - to ~/.bash_functions
saf

# Saves all defined aliases - including 'sal' and 'saf' - to ~/.bash_aliases
sal
```

## 🧹 Uninstalling

Copy and paste this command into your terminal:

```bash
uninstall_fed
```

This will remove aliases `sal` and `saf`, functions `fed`, `uninstall_fed`, and `_fed_completion`, bash completion for `fed`, and auto-load entries from `~/.bashrc`. It will also ask whether to remove `~/.bash_aliases` and `~/.bash_functions`. You can reinstall at any time as explained in the [Installing](#-installing) section.

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
- After saving, loads the (possibly renamed) function into the current shell (only for the current session)
- Automatically detects if changes were made (via MD5 hash)
- Tab completion suggests existing function names when typing `fed <TAB>`

### `sal` - Save ALiases

Alias to save all currently defined aliases.

**Syntax:**

```bash
sal
```

**Effect:**

```bash
# Equivalent to:
alias > ~/.bash_aliases
```

Takes a *snapshot* of all aliases currently defined in the shell and saves it to `~/.bash_aliases`, making them permanent across sessions.

### `saf` - Save All Functions

Alias to save all currently defined bash functions.

**Syntax:**

```bash
saf
```

**Effect:**

```bash
# Equivalent to:
declare -f > ~/.bash_functions
```

Takes a *snapshot* of all currently defined bash functions and saves it to `~/.bash_functions`, making them permanent across sessions.

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

If the given name is already an *alias*, a *keyword*, a *builtin*, or an executable *file*, an error message is printed and the workflow is stopped:

```bash
$ fed help
Error: 'help' exists and is of type 'builtin'

$ fed sed
Error: 'sed' exists and is of type 'file'

$ fed case
Error: 'case' exists and is of type 'keyword'
```

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

## ⚠️ Limitations

- You **should not** edit `~/.bash_aliases` nor `~/.bash_functions`, they will be overwritten by `sal` and `saf` respectively.

- The `sal` and `saf` commands work by taking a full *snapshot* of the current shell state (aliases and functions). **They are not incremental tools** — each snapshot completely replaces the corresponding file.

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
