{
  lib,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.neovim;
  mkUserHome = mkHome user.name;

  # Helper to create keymaps more concisely
  mkKeymap = mode: key: action: desc: {
    inherit mode key action;
    silent = true;
    noremap = true;
    inherit desc;
  };
in
{
  options.local.apps.neovim = {
    enable = lib.mkEnableOption "Neovim text editor";
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    programs.nvf = {
      enable = true;

      settings = {
        vim.viAlias = true;
        vim.vimAlias = true;
        vim.lsp = {
          enable = true;
        };

        vim.treesitter = {
          enable = true;
          fold = true;
        };

        vim.autocomplete.nvim-cmp = {
          enable = true;
        };

        vim.options.wrap = false;
        vim.options.number = true;
        vim.options.relativenumber = true;

        # Disable netrw to prevent directory listing on startup
        vim.luaConfigRC.disable-netrw = ''
          vim.g.loaded_netrw = 1
          vim.g.loaded_netrwPlugin = 1
        '';
        vim.luaConfigRC.reload-config = ''
          local function reload_config()
            local candidates = {
              vim.env.MYVIMRC,
              vim.fn.stdpath("config") .. "/init.lua",
              vim.fn.expand("~/.config/nvim/init.lua"),
              vim.fn.expand("~/.config/nvf/init.lua"),
            }

            for _, file in ipairs(candidates) do
              if file and file ~= "" and vim.fn.filereadable(file) == 1 then
                vim.cmd("source " .. vim.fn.fnameescape(file))
                vim.notify("Reloaded config: " .. file, vim.log.levels.INFO)
                return
              end
            end

            local runtime_init = vim.api.nvim_get_runtime_file("init.lua", false)[1]
            if runtime_init and runtime_init ~= "" and vim.fn.filereadable(runtime_init) == 1 then
              vim.cmd("source " .. vim.fn.fnameescape(runtime_init))
              vim.notify("Reloaded config: " .. runtime_init, vim.log.levels.INFO)
              return
            end

            vim.notify("Could not find an init.lua to reload", vim.log.levels.ERROR)
          end

          vim.api.nvim_create_user_command("ReloadConfig", reload_config, {})
        '';

        vim.visuals.cinnamon-nvim = {
          enable = true;
          setupOpts = {
            keymaps = {
              basic = true;
              extra = true;
            };
            options = {
              mode = "cursor";
            };
          };
        };

        vim.statusline.lualine = {
          enable = true;
        };

        vim.tabline.nvimBufferline = {
          enable = true;
          setupOpts = {
            options = {
              numbers = "none"; # Hide buffer numbers (or use "ordinal" for 1,2,3...)
            };
          };
        };

        vim.binds.whichKey = {
          enable = true;
        };

        vim.utility.surround = {
          enable = true;
        };

        # mini.nvim modules
        vim.mini = {
          ai.enable = true; # Better text objects
          pairs.enable = true; # Auto-pair brackets/quotes
          surround = {
            enable = true; # Add/change/delete surroundings
            setupOpts = {
              mappings = {
                add_visual = "S";
              };
            };
          };
        };

        # LSP diagnostics configuration
        vim.lsp.mappings = {
          goToDeclaration = "gD";
          goToDefinition = "gd";
          hover = "K";
          listReferences = "gr";
          nextDiagnostic = "]d";
          previousDiagnostic = "[d";
          openDiagnosticFloat = "<leader>d";
        };

        vim.filetree.neo-tree = {
          enable = true;
          setupOpts = {
            close_if_last_window = true;
            enable_git_status = true;
            enable_diagnostics = true;
            window = {
              width = 30;
            };
            filesystem = {
              follow_current_file = {
                enabled = true;
              };
              hijack_netrw_behavior = "disabled";
            };
          };
        };

        vim.utility.outline.aerial-nvim = {
          enable = true;
          mappings.toggle = "<leader>a";
          setupOpts = {
            backends = [
              "treesitter"
              "lsp"
              "markdown"
            ];
            layout = {
              default_direction = "prefer_right";
            };
          };
        };

        vim.telescope = {
          enable = true;
          mappings = {
            findFiles = "<leader>f";
            liveGrep = null;
            buffers = null;
            diagnostics = null;
            findProjects = null;
            gitFiles = null;
            lspDefinitions = null;
            lspDocumentSymbols = null;
            lspImplementations = null;
            lspReferences = null;
            lspTypeDefinitions = null;
            lspWorkspaceSymbols = null;
            resume = null;
            treesitter = null;
            helpTags = null;
            open = null;
            gitCommits = null;
            gitBufferCommits = null;
            gitBranches = null;
            gitStatus = null;
            gitStash = null;
          };
        };

        vim.keymaps = [
          (mkKeymap "n" "<leader>e" "<cmd>Neotree toggle<CR>" "Toggle Neo-tree file explorer")
          (mkKeymap "n" "<leader>s" "<cmd>AerialNavToggle<CR>" "Toggle Aerial symbols navigation")
          (mkKeymap "n" "<leader>t" "<cmd>Telescope lsp_document_symbols<CR>" "Document symbols")
          (mkKeymap "i" "jk" "<Esc><cmd>w<CR>" "Exit insert mode and save (Zed-style)")
          (mkKeymap "n" "<C-s>" "<cmd>w<CR>" "Save file")
          (mkKeymap "i" "<C-s>" "<Esc><cmd>w<CR>a" "Save file from insert mode")
          (mkKeymap "n" "<leader>O" "<cmd>ReloadConfig<CR>" "Reload Neovim config")
          (mkKeymap "n" "<C-d>" "<cmd>lua require('cinnamon').scroll('<C-d>zz')<CR>"
            "Smooth scroll half-page down and center cursor"
          )
          (mkKeymap "n" "<C-u>" "<cmd>lua require('cinnamon').scroll('<C-u>zz')<CR>"
            "Smooth scroll half-page up and center cursor"
          )

          # Window management
          (mkKeymap "n" "<leader>v" "<cmd>vsplit<CR>" "Split window vertically")
          (mkKeymap "n" "<leader>w" "<cmd>bd<CR>" "Close current buffer")

          # Window/Pane navigation (Zed-style)
          (mkKeymap "n" "<C-h>" "<C-w>h" "Move to left split")
          (mkKeymap "n" "<C-j>" "<C-w>j" "Move to bottom split")
          (mkKeymap "n" "<C-k>" "<C-w>k" "Move to top split")
          (mkKeymap "n" "<C-l>" "<C-w>l" "Move to right split")

          # Buffer navigation
          (mkKeymap "n" "H" "<cmd>bprevious<CR>" "Previous buffer")
          (mkKeymap "n" "L" "<cmd>bnext<CR>" "Next buffer")

          # Code actions
          (mkKeymap "n" "<leader>p" "<cmd>lua vim.lsp.buf.format()<CR>" "Format document")

          # Visual mode: move lines up/down
          (mkKeymap "v" "J" ":m '>+1<CR>gv=gv" "Move line down")
          (mkKeymap "v" "K" ":m '<-2<CR>gv=gv" "Move line up")

          # Visual mode: add surrounds (Zed-style)
          (mkKeymap "v" "S" "<Plug>(nvim-surround-visual)" "Add surrounds to selection")

          # Insert mode: navigation without exiting
          (mkKeymap "i" "<M-h>" "<Left>" "Move left in insert mode")
          (mkKeymap "i" "<M-j>" "<Down>" "Move down in insert mode")
          (mkKeymap "i" "<M-k>" "<Up>" "Move up in insert mode")
          (mkKeymap "i" "<M-l>" "<Right>" "Move right in insert mode")
        ];

        vim.languages = {
          lua.enable = true;
          nix.enable = true;
          python.enable = true;
          rust.enable = true;
        };
      };
    };
  });
}
