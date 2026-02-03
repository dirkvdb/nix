{
  lib,
  config,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.neovim;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.neovim = {
    enable = lib.mkEnableOption "Neovim text editor";
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      withNodeJs = true;
      withPython3 = true;

      extraPackages = with pkgs; [
        # LSP servers
        nixd
        lua-language-server
        rust-analyzer
        pyright
        typescript-language-server
        vscode-langservers-extracted

        # Formatters
        nixfmt-rfc-style
        stylua
        black
        prettier

        # Tools
        ripgrep
        fd
        tree-sitter
      ];

      plugins = with pkgs.vimPlugins; [
        # Plugin manager and dependencies
        lazy-nvim
        plenary-nvim
        nvim-web-devicons

        # UI enhancements
        which-key-nvim
        lualine-nvim
        bufferline-nvim
        indent-blankline-nvim

        # File navigation
        telescope-nvim
        telescope-fzf-native-nvim
        neo-tree-nvim
        nvim-window-picker

        # LSP
        nvim-lspconfig
        nvim-cmp
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        cmp-cmdline
        luasnip
        cmp_luasnip
        friendly-snippets

        # Treesitter
        nvim-treesitter.withAllGrammars
        nvim-treesitter-textobjects

        # Git
        gitsigns-nvim
        vim-fugitive

        # Editing
        nvim-surround
        comment-nvim
        nvim-autopairs

        # Terminal
        toggleterm-nvim

        # Symbols outline
        aerial-nvim

        # Extras
        vim-sleuth
        nvim-colorizer-lua
      ];

      extraLuaConfig = ''
        -- Basic settings
        vim.opt.number = true
        vim.opt.relativenumber = true
        vim.opt.mouse = 'a'
        vim.opt.ignorecase = true
        vim.opt.smartcase = true
        vim.opt.hlsearch = false
        vim.opt.wrap = false
        vim.opt.breakindent = true
        vim.opt.tabstop = 2
        vim.opt.shiftwidth = 2
        vim.opt.expandtab = true
        vim.opt.smartindent = true
        vim.opt.termguicolors = true
        vim.opt.signcolumn = 'yes'
        vim.opt.updatetime = 250
        vim.opt.timeoutlen = 300
        vim.opt.splitright = true
        vim.opt.splitbelow = true
        vim.opt.list = true
        vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
        vim.opt.scrolloff = 8
        vim.opt.undofile = true
        vim.opt.clipboard = 'unnamedplus'

        -- Set leader key
        vim.g.mapleader = ' '
        vim.g.maplocalleader = ' '

        -- ============================================================================
        -- PLUGIN CONFIGURATIONS
        -- ============================================================================

        -- Which-key setup
        require('which-key').setup({
          win = {
            border = 'rounded',
          },
        })

        -- Lualine
        require('lualine').setup({
          options = {
            theme = 'auto',
            component_separators = '|',
            section_separators = {},
          },
        })

        -- Bufferline
        require('bufferline').setup({
          options = {
            numbers = 'none',
            close_command = 'bdelete! %d',
            right_mouse_command = 'bdelete! %d',
            left_mouse_command = 'buffer %d',
            diagnostics = 'nvim_lsp',
            show_buffer_close_icons = true,
            show_close_icon = false,
            separator_style = 'thin',
          },
        })

        -- Neo-tree
        require('neo-tree').setup({
          close_if_last_window = false,
          popup_border_style = 'rounded',
          enable_git_status = true,
          enable_diagnostics = true,
          filesystem = {
            filtered_items = {
              hide_gitignored = true,
              hide_dotfiles = false,
            },
            follow_current_file = {
              enabled = true,
            },
          },
          window = {
            position = 'left',
            width = 30,
            mappings = {
              ['<space>e'] = 'close_window',
            },
          },
        })

        -- Telescope
        local telescope = require('telescope')
        telescope.setup({
          defaults = {
            mappings = {
              i = {
                ['<C-u>'] = false,
                ['<C-d>'] = false,
              },
            },
            layout_config = {
              horizontal = {
                preview_width = 0.55,
              },
            },
          },
          pickers = {
            find_files = {
              theme = 'dropdown',
              previewer = false,
            },
          },
          extensions = {
            fzf = {
              fuzzy = true,
              override_generic_sorter = true,
              override_file_sorter = true,
            },
          },
        })
        telescope.load_extension('fzf')

        -- Treesitter
        require('nvim-treesitter.configs').setup({
          highlight = { enable = true },
          indent = { enable = true },
          incremental_selection = {
            enable = true,
            keymaps = {
              init_selection = '<c-space>',
              node_incremental = '<c-space>',
              scope_incremental = '<c-s>',
              node_decremental = '<M-space>',
            },
          },
          textobjects = {
            select = {
              enable = true,
              lookahead = true,
              keymaps = {
                ['aa'] = '@parameter.outer',
                ['ia'] = '@parameter.inner',
                ['af'] = '@function.outer',
                ['if'] = '@function.inner',
                ['ac'] = '@class.outer',
                ['ic'] = '@class.inner',
              },
            },
            move = {
              enable = true,
              set_jumps = true,
              goto_next_start = {
                [']m'] = '@function.outer',
                [']]'] = '@class.outer',
              },
              goto_next_end = {
                [']M'] = '@function.outer',
                [']['] = '@class.outer',
              },
              goto_previous_start = {
                ['[m'] = '@function.outer',
                ['[['] = '@class.outer',
              },
              goto_previous_end = {
                ['[M'] = '@function.outer',
                ['[]'] = '@class.outer',
              },
            },
          },
        })

        -- LSP configuration
        local capabilities = require('cmp_nvim_lsp').default_capabilities()

        -- Diagnostic configuration
        vim.diagnostic.config({
          virtual_text = true,
          signs = true,
          update_in_insert = false,
          underline = true,
          severity_sort = true,
          float = {
            border = 'rounded',
            source = 'always',
          },
        })

        -- LSP keymaps (set on attach)
        local on_attach = function(client, bufnr)
          local opts = { buffer = bufnr }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
        end

        -- Setup LSP servers using new vim.lsp.config API
        -- nixd
        vim.lsp.config.nixd = {
          cmd = { 'nixd' },
          filetypes = { 'nix' },
          root_markers = { 'flake.nix', '.git' },
          capabilities = capabilities,
        }

        -- lua_ls
        vim.lsp.config.lua_ls = {
          cmd = { 'lua-language-server' },
          filetypes = { 'lua' },
          root_markers = { '.git' },
          capabilities = capabilities,
          settings = {
            Lua = {
              runtime = { version = 'LuaJIT' },
              workspace = {
                checkThirdParty = false,
                library = {
                  vim.env.VIMRUNTIME,
                },
              },
              telemetry = { enable = false },
              diagnostics = {
                globals = { 'vim' },
              },
            },
          },
        }

        -- rust_analyzer
        vim.lsp.config.rust_analyzer = {
          cmd = { 'rust-analyzer' },
          filetypes = { 'rust' },
          root_markers = { 'Cargo.toml', '.git' },
          capabilities = capabilities,
        }

        -- pyright
        vim.lsp.config.pyright = {
          cmd = { 'pyright-langserver', '--stdio' },
          filetypes = { 'python' },
          root_markers = { 'pyproject.toml', 'setup.py', '.git' },
          capabilities = capabilities,
        }

        -- ts_ls (TypeScript)
        vim.lsp.config.ts_ls = {
          cmd = { 'typescript-language-server', '--stdio' },
          filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
          root_markers = { 'package.json', 'tsconfig.json', '.git' },
          capabilities = capabilities,
        }

        -- Enable LSP servers
        local servers = { 'nixd', 'lua_ls', 'rust_analyzer', 'pyright', 'ts_ls' }
        for _, lsp in ipairs(servers) do
          vim.lsp.enable(lsp)
        end

        -- Setup on_attach for all buffers
        vim.api.nvim_create_autocmd('LspAttach', {
          callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            on_attach(client, args.buf)
          end,
        })

        -- Completion setup
        local cmp = require('cmp')
        local luasnip = require('luasnip')
        require('luasnip.loaders.from_vscode').lazy_load()

        cmp.setup({
          snippet = {
            expand = function(args)
              luasnip.lsp_expand(args.body)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ['<C-n>'] = cmp.mapping.select_next_item(),
            ['<C-p>'] = cmp.mapping.select_prev_item(),
            ['<C-d>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<CR>'] = cmp.mapping.confirm({
              behavior = cmp.ConfirmBehavior.Replace,
              select = true,
            }),
            ['<Tab>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_locally_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { 'i', 's' }),
            ['<S-Tab>'] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.locally_jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { 'i', 's' }),
          }),
          sources = {
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
            { name = 'buffer' },
            { name = 'path' },
          },
        })

        -- Gitsigns
        require('gitsigns').setup({
          signs = {
            add = { text = '+' },
            change = { text = '~' },
            delete = { text = '_' },
            topdelete = { text = '‾' },
            changedelete = { text = '~' },
          },
        })

        -- Surround
        require('nvim-surround').setup({
          keymaps = {
            insert = false,
            insert_line = false,
            normal = 'ys',
            normal_cur = 'yss',
            normal_line = 'yS',
            normal_cur_line = 'ySS',
            visual = 'S',
            visual_line = 'gS',
            delete = 'ds',
            change = 'cs',
          },
        })

        -- Comment
        require('Comment').setup()

        -- Autopairs
        require('nvim-autopairs').setup({})

        -- Integrate autopairs with cmp
        local cmp_autopairs = require('nvim-autopairs.completion.cmp')
        cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

        -- Toggleterm
        require('toggleterm').setup({
          open_mapping = [[<M-`>]],
          direction = 'horizontal',
          size = 15,
          shade_terminals = true,
        })

        -- Aerial (symbols outline)
        require('aerial').setup({
          on_attach = function(bufnr)
            vim.keymap.set('n', '<leader>s', '<cmd>AerialToggle!<CR>', { buffer = bufnr, desc = 'Toggle outline' })
          end,
          layout = {
            default_direction = 'right',
          },
        })

        -- Indent blankline
        require('ibl').setup({
          indent = {
            char = '│',
          },
          scope = {
            enabled = true,
          },
        })

        -- Colorizer
        require('colorizer').setup()

        -- ============================================================================
        -- KEYMAPS (Zed-style)
        -- ============================================================================

        local keymap = vim.keymap.set
        local opts = { noremap = true, silent = true }

        -- Better window navigation (all modes, matching Zed's ctrl-h/j/k/l)
        keymap('n', '<C-h>', '<C-w>h', opts)
        keymap('n', '<C-j>', '<C-w>j', opts)
        keymap('n', '<C-k>', '<C-w>k', opts)
        keymap('n', '<C-l>', '<C-w>l', opts)
        keymap('i', '<C-h>', '<Left>', opts)
        keymap('i', '<C-j>', '<Down>', opts)
        keymap('i', '<C-k>', '<Up>', opts)
        keymap('i', '<C-l>', '<Right>', opts)
        keymap('t', '<C-h>', '<C-\\><C-n><C-w>h', opts)
        keymap('t', '<C-j>', '<C-\\><C-n><C-w>j', opts)
        keymap('t', '<C-k>', '<C-\\><C-n><C-w>k', opts)
        keymap('t', '<C-l>', '<C-\\><C-n><C-w>l', opts)

        -- Insert mode movement (Zed's alt-h/j/k/l)
        keymap('i', '<M-h>', '<Left>', opts)
        keymap('i', '<M-j>', '<Down>', opts)
        keymap('i', '<M-k>', '<Up>', opts)
        keymap('i', '<M-l>', '<Right>', opts)

        -- jk to escape and save (Zed's jk binding)
        keymap('i', 'jk', '<Esc>:w<CR>', opts)

        -- Normal mode keybindings (space leader)
        keymap('n', '<leader>e', '<cmd>Neotree toggle<CR>', { desc = 'Toggle file explorer' })
        keymap('n', '<leader>a', '<cmd>AerialToggle! right<CR>', { desc = 'Toggle outline' })
        keymap('n', '<leader>p', function()
          vim.lsp.buf.format({ async = false })
        end, { desc = 'Format document' })
        keymap('n', '<leader>g', '<cmd>Git<CR>', { desc = 'Git panel' })

        -- Buffer navigation (Zed's shift-h/l)
        keymap('n', 'H', '<cmd>BufferLineCyclePrev<CR>', { desc = 'Previous buffer' })
        keymap('n', 'L', '<cmd>BufferLineCycleNext<CR>', { desc = 'Next buffer' })

        -- Window management
        keymap('n', '<leader>v', '<cmd>vsplit<CR>', { desc = 'Split right' })
        keymap('n', '<leader>w', '<cmd>bdelete<CR>', { desc = 'Close buffer' })
        keymap('n', '<leader>h', '<C-w>w', { desc = 'Next window' })
        keymap('n', '<leader>l', '<C-w>W', { desc = 'Previous window' })

        -- Visual mode line movement (Zed's shift-j/k)
        keymap('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move line down' })
        keymap('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move line up' })

        -- File finder (Zed's space f/t/s)
        keymap('n', '<leader>f', '<cmd>Telescope find_files<CR>', { desc = 'Find files' })
        keymap('n', '<leader>t', '<cmd>Telescope lsp_document_symbols<CR>', { desc = 'Document symbols' })
        -- Removed duplicate - already defined in Aerial setup
        keymap('n', '<leader>/', '<cmd>Telescope live_grep<CR>', { desc = 'Live grep' })
        keymap('n', '<leader>b', '<cmd>Telescope buffers<CR>', { desc = 'Find buffers' })

        -- Terminal toggle (Zed's alt-`)
        keymap('n', '<M-`>', '<cmd>ToggleTerm<CR>', { desc = 'Toggle terminal' })
        keymap('t', '<M-`>', '<cmd>ToggleTerm<CR>', opts)

        -- Additional useful keybindings
        keymap('n', '<leader>x', '<cmd>!chmod +x %<CR>', { desc = 'Make executable', silent = true })
        keymap('n', '<leader>q', '<cmd>q<CR>', { desc = 'Quit' })
        keymap('n', '<Esc>', '<cmd>nohlsearch<CR>', opts)

        -- Diagnostic keymaps
        keymap('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
        keymap('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
        keymap('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Show diagnostic' })

        -- Quick save (removed to avoid conflict with symbols/outline toggle)

        -- Better indenting
        keymap('v', '<', '<gv', opts)
        keymap('v', '>', '>gv', opts)

        -- Keep cursor centered when scrolling
        keymap('n', '<C-d>', '<C-d>zz', opts)
        keymap('n', '<C-u>', '<C-u>zz', opts)
        keymap('n', 'n', 'nzzzv', opts)
        keymap('n', 'N', 'Nzzzv', opts)

        -- Register which-key descriptions
        require('which-key').add({
          { '<leader>f', group = 'Find' },
          { '<leader>g', group = 'Git' },
          { '<leader>c', group = 'Code' },
          { '<leader>r', group = 'Rename' },
          { '<leader>w', group = 'Close Buffer' },
          { '<leader>s', group = 'Symbols/Outline' },
        })
      '';
    };
  });
}
