{
  lib,
  pkgs,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.neovim;
  mkUserHome = mkHome user.name;
  nvfTreesitterTextobjectsPatch =
    { lib, config, ... }:
    let
      inherit (lib.nvim.dag) entryAfter;
      inherit (lib.nvim.lua) toLuaObject;
      ts = config.vim.treesitter;
      tsTextobjects = ts.textobjects;
    in
    {
      config = lib.mkIf (ts.enable && tsTextobjects.enable) {
        # Patch nvf's textobjects loader to the current nvim-treesitter-textobjects API.
        vim.pluginRC.treesitter-textobjects = lib.mkForce (
          entryAfter [ "treesitter" ] ''
            local cfg = ${toLuaObject tsTextobjects.setupOpts}

            local textobjects = require("nvim-treesitter-textobjects")
            local select = require("nvim-treesitter-textobjects.select")
            local move = require("nvim-treesitter-textobjects.move")

            local setup_cfg = vim.deepcopy(cfg)

            if type(setup_cfg.select) == "table" then
              setup_cfg.select.keymaps = nil
            end

            if type(setup_cfg.move) == "table" then
              setup_cfg.move.goto_next_start = nil
              setup_cfg.move.goto_next_end = nil
              setup_cfg.move.goto_previous_start = nil
              setup_cfg.move.goto_previous_end = nil
              setup_cfg.move.goto_next = nil
              setup_cfg.move.goto_previous = nil
            end

            textobjects.setup(setup_cfg)

            local function normalize_mapping_spec(spec)
              if spec == nil or spec == false then
                return nil, nil, nil
              end

              if type(spec) == "string" then
                return spec, "textobjects", nil
              end

              if type(spec) ~= "table" then
                return nil, nil, nil
              end

              if vim.islist(spec) then
                return spec, "textobjects", nil
              end

              if spec.query == nil then
                return nil, nil, nil
              end

              return spec.query, spec.query_group or spec.queryGroup or spec.group or "textobjects", spec.desc
            end

            local function map_select(keymaps)
              if type(keymaps) ~= "table" then
                return
              end

              for lhs, spec in pairs(keymaps) do
                local query, query_group, desc = normalize_mapping_spec(spec)
                if query ~= nil then
                  vim.keymap.set({ "x", "o" }, lhs, function()
                    select.select_textobject(query, query_group)
                  end, { silent = true, desc = desc })
                end
              end
            end

            local function map_move(keymaps, method)
              if type(keymaps) ~= "table" then
                return
              end

              for lhs, spec in pairs(keymaps) do
                local query, query_group, desc = normalize_mapping_spec(spec)
                if query ~= nil then
                  vim.keymap.set({ "n", "x", "o" }, lhs, function()
                    move[method](query, query_group)
                  end, { silent = true, desc = desc })
                end
              end
            end

            if not (type(cfg.select) == "table" and cfg.select.enable == false) then
              map_select(type(cfg.select) == "table" and cfg.select.keymaps or nil)
            end

            if not (type(cfg.move) == "table" and cfg.move.enable == false) then
              local move_cfg = type(cfg.move) == "table" and cfg.move or {}
              map_move(move_cfg.goto_next_start, "goto_next_start")
              map_move(move_cfg.goto_next_end, "goto_next_end")
              map_move(move_cfg.goto_previous_start, "goto_previous_start")
              map_move(move_cfg.goto_previous_end, "goto_previous_end")
              map_move(move_cfg.goto_next, "goto_next")
              map_move(move_cfg.goto_previous, "goto_previous")
            end
          ''
        );
      };
    };

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
        imports = [ nvfTreesitterTextobjectsPatch ];

        vim.viAlias = true;
        vim.vimAlias = true;
        vim.lsp = {
          enable = true;
        };

        vim.treesitter = {
          enable = true;
          fold = true;
          grammars = with pkgs.vimPlugins.nvim-treesitter.grammarPlugins; [
            cpp
          ];
        };

        vim.treesitter.textobjects = {
          enable = true;
          setupOpts = {
            select = {
              enable = true;
              lookahead = true;
              keymaps = {
                af = "@function.outer";
                "if" = "@function.inner";
                ac = "@class.outer";
                ic = "@class.inner";
                aa = "@parameter.outer";
                ia = "@parameter.inner";
                at = "@tag.outer";
                it = "@tag.inner";
                gc = "@comment.outer";
              };
            };
            move = {
              enable = true;
              set_jumps = true;
              goto_next_start = {
                "]m" = "@function.outer";
                "]]" = [
                  "@class.outer"
                  "@function.outer"
                ];
                "]/" = "@comment.outer";
                "]*" = "@comment.outer";
              };
              goto_next_end = {
                "]M" = "@function.outer";
                "][" = [
                  "@class.outer"
                  "@function.outer"
                ];
              };
              goto_previous_start = {
                "[m" = "@function.outer";
                "[[" = [
                  "@class.outer"
                  "@function.outer"
                ];
                "[/" = "@comment.outer";
                "[*" = "@comment.outer";
              };
              goto_previous_end = {
                "[M" = "@function.outer";
                "[]" = [
                  "@class.outer"
                  "@function.outer"
                ];
              };
            };
          };
        };

        vim.autocomplete.nvim-cmp = {
          enable = true;
        };

        vim.options.wrap = false;
        vim.options.number = true;
        vim.options.relativenumber = true;
        vim.languages.enableTreesitter = true;

        vim.assistant.copilot = {
          enable = true;
          setupOpts = {
            suggestion = {
              auto_trigger = true;
            };
          };
        };

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
        vim.luaConfigRC.treesitter-zed-textobjects = ''
          local function setup_zed_treesitter()
            -- nvf currently exposes some grammar parsers under
            -- parser/vimplugin_treesitter_grammar_<lang>.so/<lang>.so.
            -- Register those parsers under their canonical language names.
            local function ensure_lang_parser(lang)
              local ok = vim.treesitter.language.add(lang)
              if ok then
                return
              end

              local nested = vim.api.nvim_get_runtime_file(
                "parser/vimplugin_treesitter_grammar_" .. lang .. ".so",
                false
              )[1]
              if not nested then
                return
              end

              local parser_path = nested .. "/" .. lang .. ".so"
              pcall(vim.treesitter.language.add, lang, { path = parser_path })
            end

            ensure_lang_parser("python")
            ensure_lang_parser("rust")
            ensure_lang_parser("nix")
            ensure_lang_parser("cpp")

            require("nvim-treesitter.configs").setup({
              incremental_selection = {
                enable = true,
                keymaps = {
                  init_selection = "[x",
                  node_incremental = "[x",
                  node_decremental = "]x",
                },
              },
            })

          end

          if vim.v.vim_did_enter == 1 then
            setup_zed_treesitter()
          else
            vim.api.nvim_create_autocmd("VimEnter", {
              once = true,
              callback = setup_zed_treesitter,
            })
          end
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
