return {
  "iamcco/markdown-preview.nvim",
  ft = { "markdown" },
  build = "cd app && rm -rf node_modules && npm install",
  cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
}
