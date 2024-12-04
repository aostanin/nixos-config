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

      globals.mapleader = ",";

      keymaps = [
        {
          key = "<leader>/";
          action = "<cmd>nohlsearch<CR>";
          options = {
            silent = true;
          };
        }
      ];

      opts = {
        # General options
        compatible = false;

        # Tab key is 4 spaces
        tabstop = 4;
        softtabstop = 4;
        shiftwidth = 4;
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
        hidden = true; # Allow unsaved changes in abandoned buffers
        backup = false; # Don't write ~ files all over
        swapfile = false; # Don't write .swp files
        cursorline = true; # Highlight current line
        ttyfast = true; # Faster redrawing
        termguicolors = true; # True color support
      };

      extraConfigLua = ''
        -- Japanese specific
        -- Allow line-breaks on Asian characters
        vim.opt.formatoptions = vim.opt.formatoptions + { 'm' }

        -- Support nfo files
        vim.api.nvim_create_autocmd({ "BufReadPre" }, {
          pattern = "*.nfo",
          callback = function()
            vim.opt_local.fileencodings = { "cp437", "utf-8" }
            vim.opt_local.list = false
          end,
        })
      '';

      colorschemes.gruvbox.enable = true;

      plugins = {
        barbar.enable = true;
        comment.enable = true;
        fugitive.enable = true;
        gitgutter.enable = true;
        lualine.enable = true;
        nix.enable = true;
        nvim-tree.enable = true;
        openscad.enable = true;
        telescope = {
          enable = true;
          keymaps = {
            "<leader>fg" = "live_grep";
            "<C-p>" = "find_files";
          };
        };
        web-devicons.enable = true;
      };
    };
  };
}
