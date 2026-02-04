# Keybindings Documentation

This document describes the unified keybindings between Zed and Neovim configurations. The Neovim setup uses **LazyVim** as the base with Zed-specific keybindings applied on top.

## Overview

- **Base**: LazyVim (a well-maintained Neovim distribution)
- **Customization**: Zed-style keybindings overlaid on top
- **Philosophy**: Minimal custom config, let LazyVim handle the complexity

## Leader Key

The leader key is set to `Space` in both editors.

## Navigation

### Window/Pane Navigation (All Modes)
- `Ctrl+h` - Move to left window/pane
- `Ctrl+j` - Move to down window/pane
- `Ctrl+k` - Move to up window/pane
- `Ctrl+l` - Move to right window/pane

### Buffer/Tab Navigation
- `Shift+h` (or `H`) - Previous buffer/tab
- `Shift+l` (or `L`) - Next buffer/tab

### Insert Mode Cursor Movement
- `Alt+h` - Move cursor left (without leaving insert mode)
- `Alt+j` - Move cursor down (without leaving insert mode)
- `Alt+k` - Move cursor up (without leaving insert mode)
- `Alt+l` - Move cursor right (without leaving insert mode)

### Smooth Scrolling
LazyVim includes `mini.animate` which provides smooth scrolling out of the box for:
- `Ctrl+u` - Scroll up half page (smooth)
- `Ctrl+d` - Scroll down half page (smooth)
- `Ctrl+b` - Scroll up full page (smooth)
- `Ctrl+f` - Scroll down full page (smooth)

## File Management

### Panels & Docks
- `Space+e` - Toggle file explorer (Neo-tree)
- `Space+a` - Toggle outline/symbols on right side (Aerial)
- `Space+s` - Toggle symbols outline (Aerial)

### File Operations
- `Space+w` - Close current buffer/file
- `Space+q` - Quit window

## Finding & Searching

- `Space+f` or `Space+ff` - Find files (Telescope fuzzy finder)
- `Space+t` or `Space+ft` - Find document symbols (Telescope)
- `Space+/` or `Space+fg` - Live grep/search in project (global search)
- `Space+b` - Find buffers (Telescope)

**Note**: For global search across all files in your project, use `Space+/` or `Space+fg` (not `g+/`)

## Code Editing

### Formatting & LSP
- `Space+p` - Format document
- `gd` - Go to definition (LazyVim default)
- `gD` - Go to declaration (LazyVim default)
- `gi` - Go to implementation (LazyVim default)
- `gr` - Go to references (LazyVim default)
- `K` - Show hover documentation (LazyVim default)
- `Space+rn` - Rename symbol (LazyVim default)
- `Space+ca` - Code actions (LazyVim default)

### Diagnostics
- `[d` - Previous diagnostic (LazyVim default)
- `]d` - Next diagnostic (LazyVim default)
- `Space+d` - Show diagnostic float

### Visual Mode Operations
- `Shift+j` (or `J` in visual) - Move selected lines down
- `Shift+k` (or `K` in visual) - Move selected lines up
- `S` - Surround selection (mini.surround)

### Text Objects & Surrounds
LazyVim includes `mini.surround` for surround operations:
- `sa{motion}` - Add surround
- `sd{char}` - Delete surround
- `sr{old}{new}` - Replace surround
- Full documentation: `:help mini.surround`

## Window Management

- `Space+v` - Split window vertically (right)
- `Ctrl+h/j/k/l` - Navigate between splits

## Terminal

- `Alt+\`` - Toggle terminal (ToggleTerm)

## Git Integration

- `Space+g` - Open LazyGit (full-featured Git UI)
- `]h` - Next git hunk (LazyVim default)
- `[h` - Previous git hunk (LazyVim default)

## Special Bindings

### Insert Mode
- `jk` - Escape insert mode and save file

### Normal Mode
- `Space+x` - Make current file executable
- `Esc` - Clear search highlighting (LazyVim default)
- `:w` - Save file (standard Vim)

### Better Editing
- `<` in visual mode - Decrease indent (stays in visual mode)
- `>` in visual mode - Increase indent (stays in visual mode)
- `n` - Next search result (centered)
- `N` - Previous search result (centered)

## LazyVim Features

LazyVim provides many additional features out of the box:

### Additional Keybindings
- `gcc` - Toggle comment line
- `gbc` - Toggle comment block
- `Space+ff` - Find files (alternative to Space+f)
- `Space+fg` - Find in files / Global search (alternative to Space+/)
- `Space+ftur` - Toggle relative line numbers
- `Space+uw` - Toggle word wrap

### Auto-completion
- `Tab` - Next completion item or expand snippet
- `Shift+Tab` - Previous completion item
- `Ctrl+Space` - Trigger completion
- `Enter` - Confirm completion

### LSP Extras
- `Space+cl` - LSP info
- `Space+cf` - Format document (alternative to Space+p)
- `Space+cr` - Rename (alternative to Space+rn)

### Telescope Extras
- `Space+ff` - Find files (alternative to Space+f)
- `Space+fr` - Recent files
- `Space+fb` - Find buffers
- `Space+fg` - Live grep (alternative to Space+/)
- `Space+fc` - Find config files
- `Space+fh` - Help tags

## LazyVim Extras Enabled

The configuration includes these LazyVim extras:

1. **coding.mini-surround** - Surround operations
2. **editor.aerial** - Symbols outline
3. **ui.mini-animate** - Smooth scrolling and animations
4. **lang.nix** - Nix language support
5. **lang.rust** - Rust language support
6. **lang.python** - Python language support
7. **lang.typescript** - TypeScript/JavaScript support

## Configuration Files

### Zed
- **Main config**: `nix/modules/home/apps/zed/default.nix`
- **Keymaps section**: Lines 182-318

### Neovim (LazyVim-based)
- **Main config**: `nix/modules/home/apps/neovim/default.nix`
- **Options**: `~/.config/nvim/lua/config/options.lua` (generated)
- **Custom keybindings**: `~/.config/nvim/lua/plugins/zed-keybindings.lua` (generated)
- **Lazy bootstrap**: `~/.config/nvim/lua/config/lazy.lua` (generated)

## Why LazyVim?

### Benefits
1. **Less maintenance** - LazyVim handles plugin updates and compatibility
2. **Best practices** - Curated plugin selection and configuration
3. **Performance** - Optimized lazy-loading of plugins
4. **Documentation** - Extensive built-in help and which-key integration
5. **Community** - Large user base and active development
6. **Extensibility** - Easy to add/remove plugins and features

### What LazyVim Provides
- **Plugin management** - Lazy.nvim for fast, lazy-loading plugins
- **LSP configuration** - Auto-configured language servers
- **Treesitter** - Syntax highlighting and code analysis
- **Telescope** - Fuzzy finder and picker
- **Neo-tree** - File explorer
- **Which-key** - Keybinding hints
- **Auto-completion** - nvim-cmp with multiple sources
- **Git integration** - Gitsigns, LazyGit, and more
- **UI enhancements** - Bufferline, Lualine, indent guides, etc.
- **Smooth scrolling** - mini.animate for smooth animations

## Customization

### Adding Zed-style Keybindings
Edit `~/.config/nvim/lua/plugins/zed-keybindings.lua` or modify the Nix configuration at `nix/modules/home/apps/neovim/default.nix`.

### Adding LazyVim Extras
Add to the `spec` section in the Nix config:
```lua
{ import = "lazyvim.plugins.extras.lang.rust" }
```

Browse available extras: https://www.lazyvim.org/extras

### Disabling Features
Create a plugin spec with `enabled = false`:
```lua
{
  "plugin-name",
  enabled = false,
}
```

## Learning More

- **LazyVim docs**: https://www.lazyvim.org
- **LazyVim keymaps**: `:help lazyvim.keymaps`
- **Which-key**: Press `Space` and wait to see available keybindings
- **Lazy plugin manager**: `Space+l` to open the UI

## Migration Notes

### Previous Custom Config
This setup replaced a large custom Neovim configuration with LazyVim to reduce maintenance burden. All Zed-style keybindings are preserved while gaining LazyVim's benefits.

### First Launch
On first launch, LazyVim will:
1. Clone lazy.nvim plugin manager
2. Install all configured plugins
3. Set up language servers and tools

This is automatic and may take a minute on first run.
