return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  ft = { "markdown" },
  opts = {
    -- Heading rendering: conceal the ## and apply per-level highlights
    heading = {
      enabled = true,
      -- Sign shown in the sign column per heading level
      signs = { "󰉫", "󰉬", "󰉭", "󰉮", "󰉯", "󰉰" },
      -- Highlight groups applied to each heading level (h1–h6)
      backgrounds = {
        "RenderMarkdownH1Bg",
        "RenderMarkdownH2Bg",
        "RenderMarkdownH3Bg",
        "RenderMarkdownH4Bg",
        "RenderMarkdownH5Bg",
        "RenderMarkdownH6Bg",
      },
      foregrounds = {
        "RenderMarkdownH1",
        "RenderMarkdownH2",
        "RenderMarkdownH3",
        "RenderMarkdownH4",
        "RenderMarkdownH5",
        "RenderMarkdownH6",
      },
    },
    -- Code blocks: add a background and language label
    code = {
      enabled = true,
      style = "full",   -- "full" renders background + language, "normal" just background
      border = "thin",
    },
    -- Bullet list icons instead of - / * / +
    bullet = {
      enabled = true,
      icons = { "●", "○", "◆", "◇" },
    },
    -- Render [ ] and [x] as checkbox icons
    checkbox = {
      enabled = true,
      unchecked = { icon = "󰄱" },
      checked   = { icon = "󰱒" },
    },
    -- Render markdown tables with box-drawing characters
    pipe_table = {
      enabled = true,
      style = "full",
    },
    -- Horizontal rules
    dash = {
      enabled = true,
      icon = "─",
    },
    -- Block quotes
    quote = {
      enabled = true,
      icon = "▋",
    },
    -- Conceal the URL part of [text](url) links
    link = {
      enabled = true,
      image    = "󰥶 ",
      hyperlink = "󰌹 ",
    },
  },
}
