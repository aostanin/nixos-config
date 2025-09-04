{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.emacs;
in {
  options.localModules.emacs = {
    enable = lib.mkEnableOption "emacs";
  };

  config = lib.mkIf cfg.enable {
    services.emacs = {
      enable = true;
    };

    programs.emacs = {
      enable = true;
      package = pkgs.emacs-pgtk;
      extraPackages = epkgs:
        with epkgs; [
          centaur-tabs
          consult
          dirvish
          doom-modeline
          doom-themes
          evil
          evil-collection
          evil-org
          git-auto-commit-mode
          gnuplot
          marginalia
          nix-mode
          orderless
          org
          org-modern
          org-roam
          rainbow-delimiters
          use-package
          valign
          vertico
          which-key
        ];
      extraConfig =
        # lisp
        ''
            (eval-when-compile
              (require 'use-package))

            (setq make-backup-files nil)
            (setq auto-save-default nil)
            (setq create-lockfiles nil)

            ;; UI improvements
            (setq initial-scratch-message nil)  ; Empty scratch buffer
            (tool-bar-mode -1)
            (menu-bar-mode -1)
            (scroll-bar-mode -1)
            (setq visible-bell t)

            ;; C-c [left,right] to undo/redo layout changes
            (winner-mode 1)

            ;; Line numbers like in Neovim
            (global-display-line-numbers-mode 1)

            ;; Highlight current line
            (global-hl-line-mode 1)

            ;; Set font to match foot terminal (Hack Nerd Font size 10)
            (set-face-attribute 'default nil :family "Hack Nerd Font" :height 100)

            ;; Theme - Gruvbox like in Neovim
            (use-package doom-themes
              :config
              (setq doom-themes-enable-bold t
                    doom-themes-enable-italic t)
              (load-theme 'doom-gruvbox t)
              (doom-themes-visual-bell-config)
              (doom-themes-org-config))

            ;; Modeline
            (use-package doom-modeline
              :init (doom-modeline-mode 1)
              :config
              (setq doom-modeline-height 25
                    doom-modeline-bar-width 3
                    doom-modeline-buffer-file-name-style 'truncate-upto-project))

            ;; Rainbow delimiters in programming modes
            (use-package rainbow-delimiters
              :hook (prog-mode . rainbow-delimiters-mode))

            (use-package evil
              :init
              (setq evil-want-integration t)
              (setq evil-want-keybinding nil)
              :config
              (evil-mode 1)
              (evil-set-leader 'normal (kbd "SPC"))
              (evil-set-leader 'normal (kbd ",") t)

              (evil-define-key 'normal 'global
                (kbd "<leader>v") 'split-window-right
                (kbd "<leader>s") 'split-window-below
                (kbd "<leader>x") 'kill-current-buffer))

            (use-package evil-collection
              :after evil
              :config
              (evil-collection-init))


            ;; Centaur Tabs - Buffer tabs like Neovim's bufferline
            (use-package centaur-tabs
              :demand
              :after evil
              :config
              (centaur-tabs-mode t)
              ;; Override M-h and M-l bindings
              (define-key evil-normal-state-map (kbd "M-h") 'centaur-tabs-move-current-tab-to-left)
              (define-key evil-normal-state-map (kbd "M-l") 'centaur-tabs-move-current-tab-to-right)
              :bind
              (:map evil-normal-state-map
                    ("H" . centaur-tabs-backward)
                    ("L" . centaur-tabs-forward)
                    ("S-<left>" . centaur-tabs-backward)
                    ("S-<right>" . centaur-tabs-forward)
                    ("M-<left>" . centaur-tabs-move-current-tab-to-left)
                    ("M-<right>" . centaur-tabs-move-current-tab-to-right)))

            ;; Vertico - vertical completion UI (like Telescope)
            (use-package vertico
              :init
              (vertico-mode)
              :config
              (setq vertico-cycle t))

            ;; Orderless - better fuzzy matching
            (use-package orderless
              :config
              (setq completion-styles '(orderless basic)
                    completion-category-overrides '((file (styles basic partial-completion)))))

            ;; Marginalia - annotations in completion
            (use-package marginalia
              :init
              (marginalia-mode))

            ;; Consult - Telescope-like commands
            (use-package consult
              :config
              (evil-define-key 'normal 'global
                (kbd "C-p") 'consult-find
                (kbd "<leader>fb") 'consult-buffer
                (kbd "<leader>fg") 'consult-ripgrep
                (kbd "<leader>fh") 'consult-info
                (kbd "<leader>fr") 'consult-recent-file
                (kbd "<leader>fs") 'consult-imenu  ; Symbol search in current file
                (kbd "<leader>fS") 'consult-imenu-multi  ; Symbol search in all buffers
                (kbd "<leader>ft") 'consult-org-agenda))

            ;; Dirvish - Modern file manager
            (use-package dirvish
              :after evil
              :init
              (dirvish-override-dired-mode)
              :config
              (setq dirvish-preview-dispatchers '(vc-diff text image))
              (evil-define-key 'normal 'global (kbd "<leader>e") 'dirvish-side))

            (use-package which-key
              :init
              (which-key-mode)
              :config
              ;; TODO: Check these config options
              (setq which-key-idle-delay 0.3)
              (setq which-key-popup-type 'side-window)
              (setq which-key-side-window-location 'bottom)
              (setq which-key-side-window-max-height 0.25)
              (setq which-key-separator " → ")
              (setq which-key-prefix-prefix "◉ "))

            (use-package nix-mode
              :mode "\\.nix\\'")

            (use-package org
              :config
              (setq org-directory "~/org")
              (setq org-default-notes-file (concat org-directory "/inbox.org"))
              (setq org-startup-with-inline-images t)
              (setq org-startup-folded 'content)
              (setq org-confirm-babel-evaluate nil)
              (setq initial-buffer-choice
                    (lambda ()
                      (org-roam-dailies-goto-today)
                      (current-buffer)))
              (setq org-capture-templates
                      '(("l" "Log entry" entry
                       (file+headline
                        (lambda ()
                          (expand-file-name
                           (format-time-string "%Y-%m-%d.org")
                           (concat org-directory "/logs/")))
                        "Log")
                       "** [%<%H:%M>] %^{Category|Personal|Food|Exercise|Work} - %?")
                      ("t" "Todo" entry (file+headline org-default-notes-file "Tasks")
                       "* TODO %i%?")
                      ("w" "Weight" table-line
                       (file+headline "~/org/areas/health.org" "Weight")
                       "| %u | %^{Weight (kg)} |"
                       :prepend t
                       :immediate-finish t)))
              (add-hook 'org-mode-hook
                (lambda ()
                  (add-hook 'before-save-hook
                            (lambda () (org-update-statistics-cookies 'all))
                            nil 'local)
                  (add-hook 'before-save-hook
                    'org-babel-execute-buffer
                    nil 'local)))
              (add-hook 'org-babel-after-execute-hook 'org-redisplay-inline-images)
              ;; TODO: Check these config options
              (setq org-startup-indented t)
              (setq org-hide-emphasis-markers t)
              (setq org-return-follows-link t)
              (setq org-todo-keywords
                    '((sequence "TODO(t)" "IN-PROGRESS(i)" "WAITING(w)" "|" "DONE(d)" "CANCELLED(c)")))
              (setq org-log-done 'time)
              (setq org-babel-python-command "${lib.getExe (pkgs.python3.withPackages (python-pkgs:
            with python-pkgs; [
              matplotlib
              numpy
              pandas
            ]))}")
              (org-babel-do-load-languages
               'org-babel-load-languages
               '((emacs-lisp . t)
                 (gnuplot . t)
                 (python . t)))
              (evil-define-key 'normal 'global
                (kbd "<leader>oa") 'org-agenda
                (kbd "<leader>oc") 'org-capture)
              (evil-define-key 'normal org-mode-map
                (kbd "<leader>od") 'org-deadline
                (kbd "<leader>ol") 'org-insert-link
                (kbd "<leader>oo") 'org-open-at-point
                (kbd "<leader>oq") 'org-set-tags-command
                (kbd "<leader>os") 'org-schedule
                (kbd "<leader>ot") 'org-todo
                (kbd "<leader>ow") 'org-refile
                (kbd "<leader>o.") 'org-time-stamp
                (kbd "<leader>o!") 'org-time-stamp-inactive)
            (evil-define-key 'normal org-capture-mode-map
              (kbd "<localleader>c") 'org-capture-finalize
              (kbd "<localleader>k") 'org-capture-kill
              (kbd "<localleader>r") 'org-capture-refile))

            (use-package org-agenda
              :after org
              :custom
              (org-agenda-files (list (concat org-directory "/inbox.org")
                        (concat org-directory "/areas/")
                        (concat org-directory "/logs/")
                        (concat org-directory "/projects/")))
              (org-refile-targets '((org-agenda-files :maxlevel . 3)))
              (org-icalendar-combined-agenda-file (concat org-directory "/calendar.ics"))
              (org-agenda-file-tags
                '(("archives/" . (:archive))
                  ("areas/" . (:area))
                  ("logs/" . (:log))
                  ("projects/" . (:project))
                  ("resources/" . (:resource))))
              :config
              (define-key org-agenda-mode-map "q" 'org-agenda-exit))

            (use-package org-roam
              :after org
              :custom
              (org-roam-directory org-directory)
              (org-roam-dailies-directory "logs/")
              :config
              (setq org-roam-directory org-directory)
              (setq org-roam-dailies-directory "logs/")
              (org-roam-db-autosync-mode)
              (setq org-roam-dailies-capture-templates
                '(("d" "default" entry ""
                   :target (file+head "%<%Y-%m-%d>.org" "${builtins.readFile ./templates/daily.org}"))))
              (setq org-roam-capture-templates
                '(("a" "area" plain "%?"
                     :target (file+head "areas/''${slug}.org" "${builtins.readFile ./templates/area.org}")
                     :unnarrowed t)
                  ("p" "project" plain "%?"
                     :target (file+head "projects/''${slug}.org" "${builtins.readFile ./templates/project.org}")
                     :unnarrowed t)
                    ("r" "resource" plain "%?"
                     :target (file+head "resources/''${slug}.org" "${builtins.readFile ./templates/resource.org}")
                     :unnarrowed t)
                  ("P" "person" plain ""
                   :target (file+head "resources/people/''${slug}.org" "${builtins.readFile ./templates/person.org}")
                   :unnarrowed t)))
              (evil-define-key 'normal 'global
                (kbd "<leader>nc") 'org-roam-capture
                (kbd "<leader>nd") 'org-roam-dailies-goto-today
                (kbd "<leader>nDd") 'org-roam-dailies-goto-date
                (kbd "<leader>nDy") 'org-roam-dailies-goto-yesterday
                (kbd "<leader>nDt") 'org-roam-dailies-goto-tomorrow
                (kbd "<leader>nf") 'org-roam-node-find
                (kbd "<leader>ni") 'org-roam-node-insert
                (kbd "<leader>nl") 'org-roam-buffer-toggle))

            (use-package gnuplot
              :config
              (setq gnuplot-program "${lib.getExe pkgs.gnuplot}"))

            ;; org-modern tables with timestamps
            (use-package valign
              :hook ((markdown-mode org-mode) . valign-mode))

            (use-package org-modern
              :hook (org-mode . org-modern-mode)
              :hook (org-agenda-finalize . org-modern-agenda)
              :config)

            (use-package evil-org
              :after (evil org)
              :hook (org-mode . evil-org-mode)
              :config
              (setq evil-want-minibuffer t)
              (evil-org-set-key-theme)
              (require 'evil-org-agenda)
              (evil-org-agenda-set-keys))

          (require 'org-attach-git)

          (require 'org-protocol)
        '';
    };
  };
}
