# Kakoune Marks Plugin

A vim-like marks system for Kakoune that allows you to set, navigate to, and manage bookmarks within your files and across your project.

## Demo

[![asciicast](https://asciinema.org/a/vX8EaVaakIEDk8MysoOnah3dl.svg)](https://asciinema.org/a/vX8EaVaakIEDk8MysoOnah3dl)

## Features

- **Local marks** (`a-z`): File-specific bookmarks that remember cursor position within the current buffer
- **Global marks** (`A-Z`): Project-wide bookmarks that remember both file and cursor position
- **Visual feedback**: Marked lines are highlighted in the editor with blue background
- **Persistent storage**: Marks are saved to a JSON file and persist across Kakoune sessions
- **Clean interface**: Vim-like key bindings with user modes for intuitive mark management

## Installation

1. Save the plugin code to your Kakoune configuration directory (e.g., `~/.config/kak/plugins/marks.kak`)
2. Source it in your `kakrc`:
   ```kak
   source "~/.config/kak/plugins/marks.kak"
   ```

The plugin will automatically create a marks file at `~/.kak_marks.json`. You can customize this location by modifying the `marks_file` option.

## Usage

### Basic Key Bindings

- `'` - Enter marks mode (shows available commands)
- `'g` - Enter goto marks mode
- `'a` - Enter add marks mode  
- `'d` - Enter delete marks mode

### Setting Marks

1. Position your cursor where you want to set a mark
2. Press `'a` to enter add marks mode
3. Press a letter:
   - `a-z`: Sets a local mark (file-specific)
   - `A-Z`: Sets a global mark (remembers file + position)

**Example**: `'aA` sets global mark A at the current cursor position

### Going to Marks

1. Press `'g` to enter goto marks mode
2. Press the mark letter you want to jump to

**Example**: `'gA` jumps to global mark A

### Deleting Marks

1. Press `'d` to enter delete marks mode
2. Press the mark letter you want to delete

**Example**: `'dA` deletes global mark A

### Viewing All Marks

Use the `:marks` command to see all currently set marks and their locations.

## Mark Types

### Local Marks (a-z)
- Tied to the current file and directory
- Only work within the same buffer
- Store cursor position as selection descriptor
- Perfect for navigating within a single file

### Global Marks (A-Z)  
- Work across different files in your project
- Store both filename and cursor position
- Allow quick jumping between files
- Ideal for marking important locations across your codebase

## Visual Feedback

Marked lines are automatically highlighted with a blue background, making it easy to see where your bookmarks are located at a glance.

## File Structure

Marks are stored in JSON format with the following structure:
```json
{
  "~/project/file.txt:mark": {
    "a": "1.5,1.10",
    "b": "15.1,15.20"
  },
  "~/project:mark": {
    "A": "file.txt:1.5,1.10",
    "B": "other.txt:25.1,25.30"
  }
}
```

## Commands

- `:mark_set <letter>` - Set a mark at current position
- `:mark_get <letter>` - Jump to specified mark
- `:mark_del <letter>` - Delete specified mark
- `:marks` - Show all marks
- `:highlight_marks` - Refresh mark highlighting (called automatically)

## Configuration

You can customize the marks file location by setting the `marks_file` option:
```kak
set-option global marks_file "/path/to/your/marks.json"
```

## Tips

- Use lowercase letters (`a-z`) for temporary, file-specific bookmarks
- Use uppercase letters (`A-Z`) for important locations you want to access from anywhere
- The `:marks` command is helpful for reviewing all your bookmarks
- Marks persist across Kakoune sessions, so you can rely on them for long-term navigation
- The visual highlighting makes it easy to see marked lines while editing

## Requirements

- Kakoune editor
- `jq` command-line JSON processor
- Basic shell utilities (`awk`, `sed`, `cut`)

This plugin brings the familiar and powerful vim marks workflow to Kakoune, making it easier to navigate large codebases and maintain your editing context across sessions.
