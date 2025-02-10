#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status

echo "Starting Neovim, Tmux, and lazygit setup script..."

# Detect operating system
OS=$(uname -s)

echo "Detected OS: $OS"

# Install Neovim and dependencies based on OS
if [[ "$OS" == "Darwin" ]]; then # macOS
	echo "macOS detected."

	# Check if Homebrew is installed
	if ! command -v brew &>/dev/null; then
		echo "Homebrew not found. Please install Homebrew first from brew.sh"
		echo "Aborting script."
		exit 1
	fi

	# Check if Neovim is installed, install if not
	if ! command -v nvim &>/dev/null; then
		echo "Neovim not found. Installing Neovim using Homebrew..."
		brew install neovim
		echo "Neovim installed."
	else
		echo "Neovim is already installed."
	fi

	# Check if jq is installed, install if not
	if ! command -v jq &>/dev/null; then
		echo "jq not found. Installing jq using Homebrew..."
		brew install jq
		echo "jq installed."
	else
		echo "jq is already installed."
	fi

	# Check if lazygit is installed, install if not
	if ! command -v lazygit &>/dev/null; then
		echo "lazygit not found. Installing lazygit using Homebrew..."
		brew install lazygit
		echo "lazygit installed."
	else
		echo "lazygit is already installed."
	fi

elif [[ "$OS" == "Linux" ]]; then # Linux (Ubuntu and similar)
	echo "Linux detected (assuming Ubuntu or Debian-based)."

	# Check if apt-get is available (common on Ubuntu/Debian)
	if ! command -v apt-get &>/dev/null; then
		echo "apt-get package manager not found. This script is designed for Ubuntu/Debian-based systems."
		echo "Please ensure you have apt-get or adapt the script for your distribution's package manager."
		echo "Aborting script."
		exit 1
	fi

	# Check if Neovim is installed, install if not
	if ! command -v nvim &>/dev/null; then
		echo "Neovim not found. Installing Neovim using apt-get..."
		sudo apt-get update # Update package lists
		sudo apt-get install -y neovim
		echo "Neovim installed."
	else
		echo "Neovim is already installed."
	fi

	# Check if jq is installed, install if not
	if ! command -v jq &>/dev/null; then
		echo "jq not found. Installing jq using apt-get..."
		sudo apt-get install -y jq
		echo "jq installed."
	else
		echo "jq is already installed."
	fi

	# Check if lazygit is installed, install if not (Ubuntu - using PPA)
	if ! command -v lazygit &>/dev/null; then
		echo "lazygit not found. Installing lazygit using apt-get (from PPA)..."
		sudo add-apt-repository ppa:lazygit-team/release
		sudo apt-get update
		sudo apt-get install -y lazygit
		echo "lazygit installed."
	else
		echo "lazygit is already installed."
	fi

else
	echo "Unsupported operating system: $OS"
	echo "This script is designed for macOS and Ubuntu."
	echo "Aborting script."
	exit 1
fi

# Create Neovim configuration directory if it doesn't exist
mkdir -p ~/.config/nvim
echo "Created Neovim configuration directory at ~/.config/nvim (if it didn't exist)."

# Install lazy.nvim plugin manager
LAZY_PATH="$HOME/.config/nvim/lazy-plugins"
if [ ! -d "$LAZY_PATH" ]; then
	echo "Installing lazy.nvim plugin manager..."
	git clone --depth 1 https://github.com/folke/lazy.nvim.git "$LAZY_PATH"
	echo "lazy.nvim installed to $LAZY_PATH."
else
	echo "lazy.nvim plugin manager is already installed."
fi

# Create init.lua configuration file if it doesn't exist, or update it
INIT_LUA_PATH="$HOME/.config/nvim/init.lua"
if [ ! -f "$INIT_LUA_PATH" ]; then
	echo "Creating default init.lua configuration file..."
	cat <<EOF >"$INIT_LUA_PATH"
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  "neovim/nvim-lspconfig",
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  "hrsh7th/nvim-cmp",
  "saadparwaiz1/cmp_nvim_lsp",
  "L3MON4D3/LuaSnip",
  "saadparwaiz1/cmp-luasnip",
  "hrsh7th/cmp-buffer",
  "hrsh7th/cmp-path",
  "hrsh7th/cmp-cmdline",
  "jose-elias-alvarez/null-ls.nvim",
  "nvim-lua/popup.nvim",
  "nvim-lua/plenary.nvim",
  "nvim-telescope/telescope.nvim",
  "nvim-tree/nvim-tree.lua",
  "lewis6991/gitsigns.nvim",
  "folke/tokyonight.nvim",
  "nvim-treesitter/nvim-treesitter",
  { "nvim-treesitter/nvim-treesitter-textobjects", after = "nvim-treesitter" },
})

vim.cmd.colorscheme "tokyonight-night"

local lspconfig = require("lspconfig")
local cmp = require('cmp')
local luasnip = require("luasnip")
local null_ls = require("null-ls")

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "typescript-language-server", "eslint_d", "prettierd" },
})

lspconfig.tsserver.setup {
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
}

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = false }),
  }),
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'buffer' },
    { name = 'path' },
    { name = 'cmdline' },
  },
})

null_ls.setup({
  sources = {
    null_ls.builtins.formatting.prettierd,
    null_ls.builtins.diagnostics.eslint_d,
  },
})

require('telescope').setup{
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      },
    },
  },
}

vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>', { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<cr>', { desc = 'Live grep' })
vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<cr>', { desc = 'Find buffers' })
vim.keymap.set('n', '<leader>fh', '<cmd>Telescope help_tags<cr>', { desc = 'Find help' })
require("nvim-tree").setup({
  sort_by = "case_sensitive",
  view = {
    adaptive_size = true,
    mappings = {
      list = {
        { key = "u", action = "dir_up" },
      },
    },
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = false,
  },
})
vim.keymap.set('n', '<leader>e', '<cmd>NvimTreeToggle<cr>', { desc = 'Toggle file explorer' })
require('gitsigns').setup()
require('nvim-treesitter.configs').setup({
  ensure_installed = { 'javascript', 'typescript', 'tsx', 'json', 'html', 'css' },
  highlight = { enable = true },
  indent = { enable = true },
  textobjects = {
    select = { enable = true, lookahead = true, keymaps = { ia = 'a', ii = 'i', aa = 'A', ai = 'I' } },
    move = { enable = true, set_jumps = true, goto_next_start = { ['}'] = '}', [']]'] = ']]' }, goto_next_end = { ['}'] = '}', [']]'] = ']]' }, goto_previous_start = { ['{'] = '{', ['[['] = '[['' }, goto_previous_end = { ['{'] = '{', ['[['] = '[[', } },
    swap = { enable = true, swap_next = { ['>a'] = '>a', ['>i'] = '>i' }, swap_previous = { ['<a'] = '<a', ['<i'] = '<i' } },
  },
})
vim.g.mapleader = " "
vim.g.maplocalleader = " "
EOF
	echo "Default init.lua configuration file created at $INIT_LUA_PATH."
else
	echo "init.lua configuration file already exists. Skipping creation."
	echo "If you want to update it, please replace the file manually."
fi

# Install Node.js and npm and global npm packages based on OS
if [[ "$OS" == "Linux" ]]; then
	# Install Node.js and npm using nvm (Node Version Manager) on Ubuntu
	if ! command -v nvm &>/dev/null; then
		echo "nvm (Node Version Manager) not found. Installing nvm..."
		curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
		export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
		[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # Load nvm into current shell
		echo "nvm installed. You might need to restart your terminal or source ~/.bashrc or ~/.zshrc for nvm command to be immediately available."
		source ~/.bashrc # Try to source bashrc to make nvm available in the current script - may not work in all cases reliably. User might need to restart shell.
	fi

	if command -v nvm &>/dev/null; then        # Check again if nvm is available after installation/sourcing
		if ! nvm ls --no-colors &>/dev/null; then # Check if any Node.js version is installed by nvm
			echo "No Node.js version managed by nvm found. Installing latest LTS Node.js using nvm..."
			nvm install --lts
			nvm use --lts # Set default LTS version
			echo "Node.js and npm installed using nvm."
		else
			echo "Node.js and npm (via nvm) are already installed."
		fi

		# Install global npm packages (prettier, eslint_d, typescript-language-server)
		echo "Installing global npm packages: prettier eslint_d typescript-language-server..."
		npm install -g prettier eslint_d typescript-language-server
		echo "Global npm packages installed."
	else
		echo "nvm installation or sourcing failed. Skipping Node.js and global npm package installation. Please ensure nvm is correctly installed and configured."
		echo "You can install Node.js and npm manually using nvm (recommended) or apt-get, and then run the script again to install global npm packages."
	fi

elif [[ "$OS" == "Darwin" ]]; then # macOS
	# Install global npm packages (prettier, eslint_d, typescript-language-server) - assuming Node.js/npm is already managed by user on macOS
	if command -v npm &>/dev/null; then
		echo "Installing global npm packages: prettier eslint_d typescript-language-server..."
		npm install -g prettier eslint_d typescript-language-server
		echo "Global npm packages installed."
	else
		echo "npm command not found on macOS. Please ensure Node.js and npm are installed and in your PATH to install global npm packages."
		echo "You can install Node.js and npm from nodejs.org or using Homebrew (brew install node)."
		echo "Skipping global npm package installation for now."
	fi
fi

# Install tmux based on OS
if [[ "$OS" == "Darwin" ]]; then # macOS
	if ! command -v tmux &>/dev/null; then
		echo "Tmux not found. Installing Tmux using Homebrew..."
		brew install tmux
		echo "Tmux installed."
	else
		echo "Tmux is already installed."
	fi
elif [[ "$OS" == "Linux" ]]; then # Linux (Ubuntu and similar)
	if ! command -v tmux &>/dev/null; then
		echo "Tmux not found. Installing Tmux using apt-get..."
		sudo apt-get install -y tmux
		echo "Tmux installed."
	else
		echo "Tmux is already installed."
	fi
fi

# Install lazygit based on OS (already added above in OS-specific sections)

# Configure tmux - create ~/.tmux.conf if it doesn't exist or update it
TMUX_CONF_PATH="$HOME/.tmux.conf"
if [ ! -f "$TMUX_CONF_PATH" ]; then
	echo "Creating default ~/.tmux.conf configuration file with weather info..."
	cat <<EOF >"$TMUX_CONF_PATH"
# Change prefix key to Ctrl+a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Set easier window and pane split keys
unbind %
bind | split-window -h
unbind '"'
bind - split-window -v

# Enable mouse mode
setw -g mode-keys vi
setw -g mouse on

# Set default terminal to 256-color xterm
set -g default-terminal "xterm-256color"
set -ag terminal-overrides ",xterm-256color:RGB" # For true color in tmux

# Status bar customization (simple)
set -g status-bg colour235
set -g status-fg colour136
set -g window-status-current-style fg=colour166,bg=colour238,bold

# --- Weather Information in Status Bar ---
# --- Customize CITY_NAME below ---
WEATHER_CITY="London"  # Change this to your city name (e.g., "New York", "Paris")
WEATHER_UNIT="metric" # "metric" for Celsius, "imperial" for Fahrenheit

WEATHER_CMD="curl -s \"http://api.openweathermap.org/data/2.5/weather?q=${WEATHER_CITY}&units=${WEATHER_UNIT}&appid=YOUR_API_KEY_HERE\" 2>/dev/null | jq -r '.main.temp, .weather[0].main'"
# IMPORTANT: Replace "YOUR_API_KEY_HERE" in the WEATHER_CMD with your actual API key from OpenWeatherMap if you want to use their service reliably.
# For this example, using city name directly might work for testing but is not recommended for production due to potential rate limits.

set -g status-right "#{?#{pane_in_mode},#{pane_mode}, } %Y-%m-%d %H:%M  #{WEATHER_CITY}: #{shellcommand \"echo $(printf '%.1f°C %s' $(head -n 1 <<<\"${WEATHER_CMD}\") $(tail -n 1 <<<\"${WEATHER_CMD}\"))\"}"
EOF
	echo "Default ~/.tmux.conf configuration file with weather info created at $TMUX_CONF_PATH."
else
	echo "~/.tmux.conf configuration file already exists. Updating it with weather info..."
	# Append weather config to existing ~/.tmux.conf (simple append - might need more sophisticated merge if you have custom config already)
	cat <<EOF >>"$TMUX_CONF_PATH"

# --- Weather Information in Status Bar ---
# --- Customize CITY_NAME below ---
WEATHER_CITY="London"  # Change this to your city name (e.g., "New York", "Paris")
WEATHER_UNIT="metric" # "metric" for Celsius, "imperial" for Fahrenheit

WEATHER_CMD="curl -s \"http://api.openweathermap.org/data/2.5/weather?q=${WEATHER_CITY}&units=${WEATHER_UNIT}&appid=YOUR_API_KEY_HERE\" 2>/dev/null | jq -r '.main.temp, .weather[0].main'"
# IMPORTANT: Replace "YOUR_API_KEY_HERE" in the WEATHER_CMD with your actual API key from OpenWeatherMap if you want to use their service reliably.
# For this example, using city name directly might work for testing but is not recommended for production due to potential rate limits.

set -g status-right "#{?#{pane_in_mode},#{pane_mode}, } %Y-%m-%d %H:%M  #{WEATHER_CITY}: #{shellcommand \"echo $(printf '%.1f°C %s' $(head -n 1 <<<\"${WEATHER_CMD}\") $(tail -n 1 <<<\"${WEATHER_CMD}\"))\"}"
EOF
	echo "~/.tmux.conf configuration file updated with weather info."
fi

echo "Neovim, Tmux, and lazygit setup script completed."
echo "-----------------------------------------"
echo "Next steps:"
echo "1. Open Neovim (nvim) or Tmux (tmux)."
echo "2. Neovim: Lazy.nvim will automatically install plugins on first startup. Restart Neovim after plugin installation."
echo "3. Tmux: Configuration is applied automatically on next Tmux session. Start tmux by typing 'tmux' in your terminal."
echo "4. Open a JavaScript file in Neovim within a Tmux session and test the IDE features."
echo "5. (Ubuntu users): If nvm installation was just performed, you might need to restart your terminal or source your shell configuration file (.bashrc or .zshrc) for nvm to be fully available in future sessions."
echo "6. **Tmux Weather:** Start a new Tmux session. You should see weather information for 'London' (or your configured city) in the right side of the status bar. To change the city, edit the WEATHER_CITY variable in ~/.tmux.conf and reload Tmux configuration (prefix + :source-file ~/.tmux.conf)."
echo "7. **lazygit:** To use lazygit, navigate to a Git repository in your terminal and type 'lazygit'."
echo "-----------------------------------------"

echo "-----------------------------------------"
echo "Neovim JavaScript IDE, Tmux & lazygit Features Summary:"
echo "-----------------------------------------"

echo ""
echo "I. Core Neovim Editing Features: (as before)"
echo "..." # (rest of Neovim features summary - keep as before)
echo ""

echo "V. Tmux Terminal Multiplexer Features (Basic Configuration + Weather): (as before)"
echo "..." # (rest of Tmux features summary - keep as before)
echo ""

echo "VI. lazygit - Terminal UI for Git:"
echo "   - Launch lazygit: Navigate to a Git repository in your terminal and run 'lazygit'."
echo "   - Easy Git Operations: Visual interface for staging, committing, branching, merging, rebasing, viewing diffs, resolving conflicts, and more."
echo "   - Powerful Features: Exposes many advanced Git commands in an accessible UI."
echo "   - Keybindings: Learn the keybindings within the lazygit UI (usually displayed at the bottom) to navigate and perform actions."
echo ""

echo "-----------------------------------------"
