{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.neovim;
in {
  options.localModules.neovim = {
    enable = lib.mkEnableOption "neovim";
  };

  config = lib.mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      withNodeJs = false;
      withRuby = false;

      nixpkgs.config.allowUnfree = true;

      globals = {
        mapleader = " ";
        maplocalleader = ",";
      };

      opts = {
        # General options
        compatible = false;
        timeoutlen = 300;

        # Tab key is 2 spaces
        tabstop = 2;
        softtabstop = 2;
        shiftwidth = 2;
        expandtab = true;

        # Indent options
        smartindent = true;

        # File encoding options
        encoding = "utf-8";
        fileencoding = "utf-8";
        fileencodings = "utf-8,euc-jp,sjis,iso-2022-jp,cp932";
        fileformats = "unix,dos,mac";

        # Show whitespace
        list = true;
        listchars = "tab:>-,extends:<,trail:-";

        # Code options
        number = true; # Show line numbers
        showmatch = true; # Show matching braces etc.

        # Search options
        wrapscan = true;
        ignorecase = true;
        smartcase = true;
        incsearch = true;
        hlsearch = true;
        gdefault = true; # Global search and replace by default

        # Status line
        laststatus = 2; # Always show

        # Tab line
        showtabline = 2; # Always show

        # Various options
        autoread = true; # Auto-refresh files
        hidden = true; # Allow unsaved changes in abandoned buffers
        backup = false; # Don't write ~ files all over
        swapfile = false; # Don't write .swp files
        cursorline = true; # Highlight current line
        termguicolors = true; # True color support
      };

      colorschemes.gruvbox.enable = true;

      keymaps = [
        {
          key = "<leader>/";
          action = "<cmd>nohlsearch<CR>";
          options = {
            silent = true;
            desc = "No highlight search";
          };
        }
        {
          key = "<leader>e";
          action = "<cmd>Neotree focus<CR>";
        }

        # Buffers
        {
          key = "<S-h>";
          action = "<cmd>BufferLineCyclePrev<CR>";
          options.desc = "Previous buffer";
        }
        {
          key = "<S-l>";
          action = "<cmd>BufferLineCycleNext<CR>";
          options.desc = "Next buffer";
        }
        {
          key = "<S-Left>";
          action = "<cmd>BufferLineCyclePrev<CR>";
          options.desc = "Previous buffer";
        }
        {
          key = "<S-Right>";
          action = "<cmd>BufferLineCycleNext<CR>";
          options.desc = "Next buffer";
        }
        {
          key = "<A-h>";
          action = "<cmd>BufferLineMovePrev<CR>";
          options.desc = "Move buffer left";
        }
        {
          key = "<A-l>";
          action = "<cmd>BufferLineMoveNext<CR>";
          options.desc = "Move buffer right";
        }
        {
          key = "<A-Left>";
          action = "<cmd>BufferLineMovePrev<CR>";
          options.desc = "Move buffer left";
        }
        {
          key = "<A-Right>";
          action = "<cmd>BufferLineMoveNext<CR>";
          options.desc = "Move buffer right";
        }
        {
          key = "<leader>x";
          action = "<cmd>Bdelete<CR>";
          options.desc = "Close buffer";
        }
        {
          key = "<leader>b";
          action = "";
          options.desc = "Bufferline";
        }
        {
          key = "<leader>bp";
          action = "<cmd>BufferLineTogglePin<CR>";
          options.desc = "Pin/unpin buffer";
        }
        {
          key = "<leader>bP";
          action = "<cmd>BufferLinePick<CR>";
          options.desc = "Pick buffer";
        }
        {
          key = "<leader>bc";
          action = "<cmd>BufferLinePickClose<CR>";
          options.desc = "Pick buffer to close";
        }

        # Splits
        {
          key = "<leader>v";
          action = "<cmd>vsplit<CR>";
          options.desc = "Split vertically";
        }
        {
          key = "<leader>s";
          action = "<cmd>split<CR>";
          options.desc = "Split horizontally";
        }

        # Terminal
        {
          key = "<Esc><Esc>";
          action = "<C-\\><C-n>";
          mode = "t";
          options.desc = "Exit terminal";
        }
        {
          key = "<C-w>h";
          action = "<C-\\><C-n><C-w>h";
          mode = "t";
          options.desc = "Move to left window";
        }
        {
          key = "<C-w>l";
          action = "<C-\\><C-n><C-w>l";
          mode = "t";
          options.desc = "Move to right window";
        }
        {
          key = "<C-w>j";
          action = "<C-\\><C-n><C-w>j";
          mode = "t";
          options.desc = "Move to window below";
        }
        {
          key = "<C-w>k";
          action = "<C-\\><C-n><C-w>k";
          mode = "t";
          options.desc = "Move to window above";
        }

        # Copy to system clipboard
        {
          mode = ["n" "v"];
          key = "<leader>y";
          action = ''"+y'';
          options.desc = "Copy to system clipboard";
        }
        {
          mode = ["n" "v"];
          key = "<leader>Y";
          action = ''"+Y'';
          options.desc = "Copy line to system clipboard";
        }

        # Paste from system clipboard
        {
          mode = ["n" "v"];
          key = "<leader>p";
          action = ''"+p'';
          options.desc = "Paste from system clipboard";
        }
        {
          mode = ["n" "v"];
          key = "<leader>P";
          action = ''"+P'';
          options.desc = "Paste before from system clipboard";
        }

        # Comments
        {
          mode = "n";
          key = "<C-_>";
          action = "gcc";
          options = {
            remap = true;
            desc = "Toggle comment";
          };
        }
        {
          mode = "v";
          key = "<C-_>";
          action = "gc";
          options = {
            remap = true;
            desc = "Toggle comment";
          };
        }

        # Claude Code
        {
          key = "<leader>a";
          action = "";
          options.desc = "AI/Claude Code";
        }
        {
          key = "<leader>ac";
          action = "<cmd>ClaudeCode<CR>";
          options.desc = "Toggle Claude";
        }
        {
          key = "<leader>af";
          action = "<cmd>ClaudeCodeFocus<CR>";
          options.desc = "Focus Claude";
        }
        {
          key = "<leader>ar";
          action = "<cmd>ClaudeCode --resume<CR>";
          options.desc = "Resume Claude";
        }
        {
          key = "<leader>aC";
          action = "<cmd>ClaudeCode --continue<CR>";
          options.desc = "Continue Claude";
        }
        {
          key = "<leader>am";
          action = "<cmd>ClaudeCodeSelectModel<CR>";
          options.desc = "Select Claude model";
        }
        {
          key = "<leader>ab";
          action = "<cmd>ClaudeCodeAdd %<CR>";
          options.desc = "Add current buffer";
        }
        {
          mode = "v";
          key = "<leader>as";
          action = "<cmd>ClaudeCodeSend<CR>";
          options.desc = "Send to Claude";
        }
        {
          key = "<leader>aa";
          action = "<cmd>ClaudeCodeDiffAccept<CR>";
          options.desc = "Accept diff";
        }
        {
          key = "<leader>ad";
          action = "<cmd>ClaudeCodeDiffDeny<CR>";
          options.desc = "Deny diff";
        }

        # Keep visual selection after indent
        {
          mode = "v";
          key = ">";
          action = ">gv";
          options.desc = "Indent and reselect";
        }
        {
          mode = "v";
          key = "<";
          action = "<gv";
          options.desc = "Outdent and reselect";
        }

        # Telescope
        {
          key = "<leader>f";
          action = "";
          options.desc = "Telescope";
        }
        {
          key = "<leader>ft";
          action = "<cmd>TodoTelescope<CR>";
          options.desc = "Telescope Todo";
        }
      ];

      extraConfigLua = ''
        -- OpenCode keybindings
        vim.keymap.set({ "n", "x" }, "<C-a>", function() require("opencode").ask("", { submit = true }) end, { desc = "Ask opencode" })
        vim.keymap.set({ "n", "x" }, "<C-x>", function() require("opencode").select() end, { desc = "Execute opencode action…" })
        vim.keymap.set({ "n", "t" }, "<C-.>", function() require("opencode").toggle() end, { desc = "Toggle opencode" })

        vim.keymap.set({ "n", "x" }, "go",  function() return require("opencode").operator("") end, { expr = true, desc = "Add range to opencode" })
        vim.keymap.set("n", "goo", function() return require("opencode").operator("") .. "_" end, { expr = true, desc = "Add line to opencode" })

        vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end, { desc = "opencode half page up" })
        vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end, { desc = "opencode half page down" })

        -- Remap + and - for increment/decrement (overriding the C-a/C-x functions above)
        vim.keymap.set("n", "+", "<C-a>", { desc = "Increment", noremap = true })
        vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement", noremap = true })

        -- Japanese specific
        -- Allow line-breaks on Asian characters
        vim.opt.formatoptions = vim.opt.formatoptions + { 'm' }

        -- Refresh files
        vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, { command = "checktime" })

        -- Support nfo files
        vim.api.nvim_create_autocmd({ "BufReadPre" }, {
          pattern = "*.nfo",
          callback = function()
            vim.opt_local.fileencodings = { "cp437", "utf-8" }
            vim.opt_local.list = false
          end,
        })

        -- For auto-session
        vim.opt.sessionoptions="blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

        require('claudecode').setup({
          terminal = {
            split_width_percentage = 0.5,
          },
          diff_opts = {
            keep_terminal_focus = true,
          },

          -- Keymaps don't seem to work, so disable and set manually
          keymaps = {
            toggle = {
              normal = false,
              terminal = false,
              variants = {
                continue = false,
                verbose = false,
              },
            },
            window_navigation = false,
            scrolling = false,
          },
        })

        -- Auto-unlist claude-code buffer
        vim.api.nvim_create_autocmd("TermOpen", {
          pattern = "*",
          callback = function()
            local buf_name = vim.api.nvim_buf_get_name(0)
            if string.find(buf_name, "claude-") then
              vim.bo.buflisted = false
            end
          end,
        })

        -- Filetype-specific keybinding for ClaudeCodeTreeAdd
        vim.api.nvim_create_autocmd("FileType", {
          pattern = { "NvimTree", "neo-tree", "oil" },
          callback = function()
            vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", {
              buffer = true,
              desc = "Add file",
            })
          end,
        })
      '';

      env = {
        # For diagram mmdc
        PUPPETEER_EXECUTABLE_PATH = lib.getExe pkgs.firefox;
      };

      extraPackages = with pkgs; [
        # For diagram
        d2
        gnuplot
        mermaid-cli
        plantuml
      ];

      extraPlugins = [
        # ref: https://github.com/nix-community/nixvim/issues/3500
        pkgs.unstable.vimPlugins.claudecode-nvim
      ];

      plugins = {
        auto-session.enable = true;

        blink-copilot.enable = true;

        blink-cmp = {
          enable = true;
          settings = {
            sources = {
              default = [
                "copilot"
                "lsp"
                "path"
                "snippets"
                "buffer"
              ];
              providers.copilot = {
                name = "copilot";
                module = "blink-copilot";
                score_offset = 100;
                async = true;
                opts = {
                  max_completions = 3;
                  max_attempts = 4;
                  kind_name = "Copilot";
                  kind_icon = " ";
                  kind_hl = false;
                  debounce = 200;
                  auto_refresh = {
                    backward = true;
                    forward = true;
                  };
                };
              };
            };
          };
        };

        bufdelete.enable = true;

        bufferline.enable = true;

        comment.enable = true;

        conform-nvim = {
          enable = true;
          settings = {
            formatters_by_ft = {
              elm = ["elm_format"];
              go = ["gofmt"];
              javascript = ["biome" "biome-organize-imports"];
              javascriptreact = ["biome" "biome-organize-imports"];
              lisp = ["emacs_elisp"];
              markdown = ["prettier"];
              nix = ["alejandra" "injected"];
              python = ["black"];
              rust = ["rustfmt"];
              sh = ["shfmt"];
              sql = ["pg_format"];
              typescript = ["biome" "biome-organize-imports"];
              typescriptreact = ["biome" "biome-organize-imports"];
              yaml = ["prettier"];
            };
            format_on_save = {
              lsp_format = "fallback";
              timeout_ms = 500;
            };
            formatters = {
              alejandra.command = lib.getExe pkgs.alejandra;
              black.command = lib.getExe pkgs.black;
              biome.command = lib.getExe pkgs.biome;
              biome-organize-imports.command = lib.getExe pkgs.biome;
              elm_format.command = lib.getExe pkgs.elmPackages.elm-format;
              gofmt.command = lib.getExe' pkgs.go "gofmt";
              pg_format.command = lib.getExe pkgs.pgformatter;
              prettier.command = lib.getExe pkgs.nodePackages.prettier;
              rustfmt.command = lib.getExe pkgs.rustPackages.rustfmt;
              shfmt = {
                command = lib.getExe pkgs.shfmt;
                prepend_args = ["-i" "2" "-ci" "-bn"];
              };
              emacs_elisp = {
                command = "sh";
                args = [
                  "-c"
                  "tmpfile=$(mktemp); cat > \"$tmpfile\"; ${lib.getExe pkgs.emacs-nox} -Q --batch --eval \"(let ((inhibit-message t) (message-log-max nil) (indent-tabs-mode nil)) (with-temp-buffer (insert-file-contents \\\"$tmpfile\\\") (emacs-lisp-mode) (indent-region (point-min) (point-max)) (princ (buffer-substring-no-properties (point-min) (point-max)))))\"; rm -f \"$tmpfile\""
                ];
              };
            };
          };
        };

        copilot-lua = {
          enable = true;
          settings = {
            suggestion.enabled = false;
            panel.enabled = false;
          };
        };

        diagram.enable = true;

        gitsigns = {
          enable = true;
          settings.current_line_blame = true;
        };

        guess-indent.enable = true;

        image = {
          enable = false;
          settings = {
            # TODO: Switch to a term that supports kitty image protocol?
            backend = "ueberzug";
            integrations = {
              markdown = {
                only_render_image_at_cursor = true;
                only_render_image_at_cursor_mode = "popup";
              };
            };
          };
        };

        lsp = {
          enable = true;
          keymaps = {
            lspBuf = {
              "gd" = "definition";
              "gr" = "references";
              "K" = "hover";
              "<leader>rn" = "rename";
              "<leader>ca" = "code_action";
            };
            diagnostic = {
              "[d" = "goto_prev";
              "]d" = "goto_next";
            };
          };
          servers = {
            basedpyright.enable = true;
            bashls.enable = true;
            elmls.enable = true;
            gopls.enable = true;
            marksman.enable = true;
            nixd.enable = true;
            openscad_lsp.enable = true;
            rust_analyzer = {
              enable = true;
              installCargo = true;
              installRustc = true;
            };
            vtsls.enable = true;
          };
        };

        lualine.enable = true;

        neo-tree = {
          enable = true;
          settings.filesystem = {
            filtered_items.visible = true;
            follow_current_file.enabled = true;
          };
        };

        neogit.enable = true;

        neorg = {
          enable = false;
          settings = {
            load = {
              "core.concealer" = {
                config = {
                  icon_preset = "varied";
                };
              };
              "core.defaults" = {
                __empty = null;
              };
              "core.dirman" = {
                config = {
                  workspaces = {
                    notes = "~/Sync/norg";
                  };
                };
              };
              "core.journal" = {
                config = {
                  strategy = "flat";
                };
              };
            };
          };
          telescopeIntegration.enable = true;
        };

        oil = {
          enable = false;
          settings = {
            default_file_explorer = true;
            view_options = {
              show_hidden = true;
            };
          };
        };

        opencode = {
          enable = true;
          package = pkgs.unstable.vimPlugins.opencode-nvim.overrideAttrs (old: {
            runtimeDeps = old.runtimeDeps ++ [pkgs.lsof];
          });
          settings = {
            # port = 24817;
            provider = {
              enabled = "snacks";
              cmd = lib.getExe pkgs.unstable.opencode;
            };
          };
        };

        render-markdown.enable = true;

        snacks = {
          enable = true;
          settings = {
            input.enable = true;
            picker.enable = true;
            terminal.enable = true;
          };
        };

        telescope = {
          enable = true;
          keymaps = {
            "<C-p>" = "find_files";
            "<leader>fb" = "buffers";
            "<leader>fd" = "diagnostics";
            "<leader>fg" = "live_grep";
            "<leader>fh" = "help_tags";
            "<leader>fk" = "keymaps";
            "<leader>fr" = "lsp_references";
            "<leader>fs" = "lsp_document_symbols";
            "<leader>fS" = "lsp_workspace_symbols";
          };
          settings = {
            defaults = {
              file_ignore_patterns = [".git/"];
            };
            pickers = {
              find_files = {
                hidden = true;
              };
            };
          };
        };

        todo-comments.enable = true;

        treesitter = {
          enable = true;
          settings = {
            highlight.enable = true;
            indent.enable = true;
          };
        };

        web-devicons.enable = true;

        which-key = {
          enable = true;
          settings = {
            delay = 200;
            preset = "modern";
          };
        };
      };
    };
  };
}
