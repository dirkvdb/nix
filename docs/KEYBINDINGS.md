# Keybindings Documentation

This document describes the unified keybindings between Zed and Neovim configurations, ensuring both editors behave consistently.

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

### Smooth Scrolling (Neovim)
The following commands have smooth scrolling enabled:
- `Ctrl+u` - Scroll up half page (smooth + auto-centered)
- `Ctrl+d` - Scroll down half page (smooth + auto-centered)
- `Ctrl+b` - Scroll up full page (smooth)
- `Ctrl+f` - Scroll down full page (smooth)
- `Ctrl+y` - Scroll up one line (smooth)
- `Ctrl+e` - Scroll down one line (smooth)
- `zt` - Move current line to top (smooth)
- `zz` - Move current line to center (smooth)
- `zb` - Move current line to bottom (smooth)

## File Management

### Panels & Docks
- `Space+e` - Toggle file explorer (left dock)
- `Space+a` - Toggle outline/symbols (right dock)
- `Space+s` - Toggle symbols outline (when in a buffer with LSP support)

### File Operations
- `Space+w` - Close current buffer/file
- `Space+q` - Quit window

## Finding & Searching

- `Space+f` - Find files (fuzzy finder)
- `Space+t` - Find document symbols
- `Space+/` - Live grep/search in project
- `Space+b` - Find open buffers

## Code Editing

### Formatting & LSP
- `Space+p` - Format document
- `gd` - Go to definition
- `gD` - Go to declaration
- `gi` - Go to implementation
- `gr` - Go to references
- `K` - Show hover documentation
- `Ctrl+k` - Show signature help
- `Space+rn` - Rename symbol
- `Space+ca` - Code actions

### Diagnostics
- `[d` - Previous diagnostic
- `]d` - Next diagnostic
- `Space+d` - Show diagnostic float

### Visual Mode Operations
- `Shift+j` (or `J` in visual) - Move selected lines down
- `Shift+k` (or `K` in visual) - Move selected lines up
- `S` - Surround selection (in visual mode)

### Text Objects & Surrounds
- `ys{motion}` - Add surround
- `ds{char}` - Delete surround
- `cs{old}{new}` - Change surround
- `yss` - Surround entire line
- `yS{motion}` - Add surround on new lines
- `ySS` - Surround entire line on new lines

## Window Management

- `Space+v` - Split window vertically (right)
- `Space+h` - Next window
- `Space+l` - Previous window

## Terminal

- `Alt+\`` - Toggle terminal

## Git Integration

- `Space+g` - Open Git panel

## Special Bindings

### Insert Mode
- `jk` - Escape insert mode and save file

### Normal Mode
- `Space+x` - Make current file executable
- `Esc` - Clear search highlighting
- `:w` - Save file (standard Vim command)

### Better Editing
- `<` in visual mode - Decrease indent (stays in visual mode)
- `>` in visual mode - Increase indent (stays in visual mode)
- `Ctrl+d` - Scroll down half page (smooth animation + auto-centered)
- `Ctrl+u` - Scroll up half page (smooth animation + auto-centered)
- `n` - Next search result (centered)
- `N` - Previous search result (centered)

## Plugin-Specific Features

### Completion (Insert Mode)
- `Ctrl+Space` - Trigger completion
- `Ctrl+n` - Next completion item
- `Ctrl+p` - Previous completion item
- `Enter` - Confirm completion
- `Tab` - Next completion item or expand snippet
- `Shift+Tab` - Previous completion item or jump back in snippet

### Treesitter Text Objects
- `aa` - Around argument/parameter
- `ia` - Inside argument/parameter
- `af` - Around function
- `if` - Inside function
- `ac` - Around class
- `ic` - Inside class

### Function/Class Navigation
- `]m` - Next function start
- `]M` - Next function end
- `[m` - Previous function start
- `[M` - Previous function end
- `]]` - Next class start
- `][` - Next class end
- `[[` - Previous class start
- `[]` - Previous class end

## Neovim-Specific Features

While most keybindings are identical to Zed, Neovim includes these additional features:

1. **LSP Navigation**: More granular LSP keybindings (gd, gD, gi, gr) compared to Zed's simpler navigation
2. **Treesitter Text Objects**: Enhanced text object selections using treesitter
3. **Additional Motions**: Neovim includes vim-native motions and text objects
4. **Which-key**: Shows available keybindings after pressing leader key (with ~300ms delay)
5. **Smooth Scrolling**: All scroll commands animate smoothly for better visual tracking
6. **Operator Overlaps**: Some keybindings like `ys`, `ds`, `cs` are operators that wait for motions (this is expected Vim behavior)

## Configuration Files

- **Zed**: `nix/modules/home/apps/zed/default.nix` (lines 182-318)
- **Neovim**: `nix/modules/home/apps/neovim/default.nix` (lines 100-600)

### Note on Neovim LSP Configuration

The Neovim configuration uses the modern `vim.lsp.config` API (introduced in Neovim 0.11) instead of the deprecated `require('lspconfig')` framework. This provides better integration with Neovim's built-in LSP client.

### Known Warnings

- **Which-key overlapping keymaps**: Some warnings about overlapping keymaps (e.g., `<Space>` with `<Space>g`, `y` with `ys`, etc.) are expected and normal. These are operator-pending keymaps that wait for additional input, which is standard Vim behavior.

## Customization

To add new keybindings:

1. For Zed: Add to `userKeymaps` array in the Zed configuration
2. For Neovim: Add to the keymaps section in `extraLuaConfig`

Ensure both configurations are updated to maintain consistency across editors.

## Smooth Scrolling Configuration

Neovim's smooth scrolling is powered by `neoscroll.nvim` using modern helper functions API with the following settings:
- **Easing**: Quadratic (smooth acceleration/deceleration)
- **Hide cursor during scroll**: Yes (reduces visual noise)
- **Stop at end of file**: Yes (prevents over-scrolling)
- **Auto-centering**: Enabled for `Ctrl+u` and `Ctrl+d` (cursor stays centered)
- **Animation duration**: 
  - Half-page scrolls (`Ctrl+u`/`Ctrl+d`): 150ms with auto-centering
  - Full-page scrolls (`Ctrl+b`/`Ctrl+f`): 250ms
  - Line scrolls (`Ctrl+y`/`Ctrl+e`): 100ms
  - Repositioning (`zt`/`zz`/`zb`): 150ms
- **Performance mode**: Disabled (prioritizes smoothness)
- **API**: Uses modern helper functions (`neoscroll.scroll()`, `neoscroll.zt()`, etc.) instead of deprecated `set_mappings()`

You can adjust the scrolling behavior by modifying the neoscroll setup in the Neovim configuration file. Each command is configured with explicit duration and cursor behavior options.