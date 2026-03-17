-- ~/.config/nvim/lua/plugins/snacks.lua
--
-- Dependencies (Ubuntu):
--   pokemon-colorscripts is not in apt. Install from source:
--     git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git
--     cd pokemon-colorscripts
--     ./install.sh          # requires sudo, installs to /usr/local
--
--   If sudo is unavailable, install to user-local instead:
--     mkdir -p ~/.local/opt/pokemon-colorscripts ~/.local/bin
--     cp -r colorscripts pokemon-colorscripts.py pokemon.json ~/.local/opt/pokemon-colorscripts/
--     ln -sf ~/.local/opt/pokemon-colorscripts/pokemon-colorscripts.py ~/.local/bin/pokemon-colorscripts
--     chmod +x ~/.local/opt/pokemon-colorscripts/pokemon-colorscripts.py
--     # Also add to ~/.zshrc or ~/.bashrc:
--     #   export PATH=$HOME/.local/bin:$PATH
--
--   The cmd below uses the absolute path so nvim finds it regardless of $PATH.

return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
        sections = {
            { section = "header" },
            { section = "keys", gap = 1, padding = 1 },
            { section = "startup" },
            {
            section = "terminal",
            cmd = os.getenv("HOME") .. "/.local/bin/pokemon-colorscripts -r --no-title; sleep .1",
            random = 10,
            pane = 2,
            indent = 4,
            height = 30,
            },
        },
    },
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
        },
      },
    },
  },
}
