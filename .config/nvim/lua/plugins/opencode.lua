return {
  "NickvanDyke/opencode.nvim",
  version = "*",
  config = false, -- configured via vim.g.opencode_opts; no setup() exists
  dependencies = {
    {
      "folke/snacks.nvim",
      optional = true,
      opts = {
        input = { enabled = true },
        picker = {
          actions = {
            opencode_send = function(...)
              return require("opencode").snacks_picker_send(...)
            end,
          },
          win = {
            input = {
              keys = {
                ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
              },
            },
          },
        },
      },
    },
  },
  keys = {
    -- <A-o> in normal mode: open+focus if hidden, hide if visible
    {
      "<A-o>",
      function()
        local function find_term_win()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "terminal" then
              return win
            end
          end
        end
        local term_win = find_term_win()
        if term_win then
          -- TUI is visible — hide it
          require("opencode").toggle()
        else
          -- TUI is hidden — open and focus it
          require("opencode").toggle()
          vim.defer_fn(function()
            local win = find_term_win()
            if win then
              vim.api.nvim_set_current_win(win)
              vim.cmd("startinsert")
            end
          end, 100)
        end
      end,
      mode = "n",
      desc = "opencode: toggle TUI",
    },
    -- <A-o> in terminal mode: return to editor
    { "<A-o>", "<C-\\><C-n><C-w>p", mode = "t", desc = "opencode: return to editor" },

    -- Ask / action menu
    { "<leader>aa", function() require("opencode").ask() end,    mode = { "n", "x" }, desc = "opencode: ask" },
    { "<leader>as", function() require("opencode").select() end, mode = { "n", "x" }, desc = "opencode: action menu" },

    -- Operator (works with motions, e.g. `go$`, `goip`; `goo` = current line)
    { "go",  function() return require("opencode").operator("@this ") end,        mode = { "n", "x" }, expr = true, desc = "opencode: send range" },
    { "goo", function() return require("opencode").operator("@this ") .. "_" end, mode = "n",          expr = true, desc = "opencode: send line" },

    -- Named prompts  (<leader>o + mnemonic)
    { "<leader>oe", function() require("opencode").prompt("explain")    end, mode = { "n", "x" }, desc = "opencode: explain" },
    { "<leader>of", function() require("opencode").prompt("fix")        end, mode = { "n", "x" }, desc = "opencode: fix diagnostics" },
    { "<leader>or", function() require("opencode").prompt("review")     end, mode = { "n", "x" }, desc = "opencode: review" },
    { "<leader>od", function() require("opencode").prompt("document")   end, mode = { "n", "x" }, desc = "opencode: document" },
    { "<leader>ot", function() require("opencode").prompt("test")       end, mode = { "n", "x" }, desc = "opencode: add tests" },
    { "<leader>oi", function() require("opencode").prompt("implement")  end, mode = { "n", "x" }, desc = "opencode: implement" },
    { "<leader>op", function() require("opencode").prompt("optimize")   end, mode = { "n", "x" }, desc = "opencode: optimize" },
    { "<leader>oD", function() require("opencode").prompt("diff")       end, mode = "n",          desc = "opencode: review diff" },

    -- Session management
    { "<leader>on", function() require("opencode").command("session.new")       end, desc = "opencode: new session" },
    { "<leader>ol", function() require("opencode").select_session()             end, desc = "opencode: list sessions" },
    { "<leader>ou", function() require("opencode").command("session.undo")      end, desc = "opencode: undo" },
    { "<leader>oR", function() require("opencode").command("session.redo")      end, desc = "opencode: redo" },
    { "<leader>oc", function() require("opencode").command("session.compact")   end, desc = "opencode: compact session" },
    { "<leader>ox", function() require("opencode").command("session.interrupt") end, desc = "opencode: interrupt" },

    -- Scroll the TUI from normal mode
    { "<S-PageUp>",   function() require("opencode").command("session.half.page.up")   end, desc = "opencode: scroll up" },
    { "<S-PageDown>", function() require("opencode").command("session.half.page.down") end, desc = "opencode: scroll down" },
  },
}
