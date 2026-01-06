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

        # Sidekick
        {
          key = "<leader>a";
          action = "";
          options.desc = "AI/Sidekick";
        }
        {
          key = "<C-.>";
          action.__raw = ''function() require("sidekick.cli").toggle() end'';
          mode = ["n" "t" "i" "x"];
          options.desc = "Sidekick Toggle";
        }
        {
          key = "<leader>aa";
          action.__raw = ''function() require("sidekick.cli").toggle() end'';
          options.desc = "Sidekick Toggle CLI";
        }
        {
          key = "<leader>as";
          action.__raw = ''function() require("sidekick.cli").select() end'';
          options.desc = "Select CLI";
        }
        {
          key = "<leader>ad";
          action.__raw = ''function() require("sidekick.cli").close() end'';
          options.desc = "Detach CLI Session";
        }
        {
          key = "<leader>at";
          action.__raw = ''function() require("sidekick.cli").send({ msg = "{this}" }) end'';
          mode = ["n" "x"];
          options.desc = "Send This";
        }
        {
          key = "<leader>af";
          action.__raw = ''function() require("sidekick.cli").send({ msg = "{file}" }) end'';
          options.desc = "Send File";
        }
        {
          key = "<leader>av";
          action.__raw = ''function() require("sidekick.cli").send({ msg = "{selection}" }) end'';
          mode = ["x"];
          options.desc = "Send Visual Selection";
        }
        {
          key = "<leader>ap";
          action.__raw = ''function() require("sidekick.cli").prompt() end'';
          mode = ["n" "x"];
          options.desc = "Sidekick Select Prompt";
        }
        {
          key = "<leader>ac";
          action.__raw = ''function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end'';
          options.desc = "Sidekick Toggle Claude";
        }
        {
          key = "<leader>ao";
          action.__raw = ''function() require("sidekick.cli").toggle({ name = "opencode", focus = true }) end'';
          options.desc = "Sidekick Toggle OpenCode";
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
        # For sidekick CLI process detection
        lsof
      ];

      extraPlugins = [
      ];

      plugins = {
        auto-session.enable = true;

        blink-copilot.enable = true;

        blink-cmp = {
          enable = true;
          settings = {
            keymap = {
              "<Tab>" = [
                "snippet_forward"
                {
                  __raw = ''
                    function()
                      return require("sidekick").nes_jump_or_apply()
                    end
                  '';
                }
                "fallback"
              ];
            };
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
                  kind_icon = " ";
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

        render-markdown.enable = true;

        sidekick = {
          enable = true;
          settings = {
            cli = {
              mux = {
                backend = "tmux";
                enabled = true;
              };
              tools = {
                claude = {
                  cmd = [(lib.getExe pkgs.unstable.claude-code)];
                };
                opencode = {
                  cmd = [(lib.getExe pkgs.unstable.opencode)];
                };
              };
            };
          };
        };

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
