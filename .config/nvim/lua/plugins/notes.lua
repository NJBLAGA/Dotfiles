return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        ["<leader>N"] = { name = "📝 Notes" },
        ["<leader>No"] = { desc = "📂 Open Note(s)" },
        ["<leader>Nb"] = { desc = "🌐 Preview Note In Browser" },
        ["<leader>Nc"] = { desc = "📄 Create New Note" },
        ["<leader>Nr"] = { desc = "✏️ Rename Note" },
        ["<leader>Nd"] = { desc = "🗑️ Delete Note(s)" },
        ["<leader>Ng"] = { desc = "📝 Git Commit Changes" },
        ["<leader>Np"] = { desc = "🚀 Git Push to GitHub" },
      },
    },
  },

  {
    "nvim-telescope/telescope.nvim",
    keys = {

      -- 1️⃣ 📂 Open Note(s)
      {
        "<leader>No",
        function()
          local notes_dir = vim.fn.expand("~/Dev/Notes")
          require("telescope.builtin").find_files({
            prompt_title = "Open Note(s)",
            cwd = notes_dir,
            attach_mappings = function(_, map)
              local actions = require("telescope.actions")
              local action_state = require("telescope.actions.state")

              map("i", "<Tab>", actions.toggle_selection)
              map("n", "<Tab>", actions.toggle_selection)

              map("i", "<CR>", function(prompt_bufnr)
                local picker = action_state.get_current_picker(prompt_bufnr)
                local selections = picker:get_multi_selection()
                actions.close(prompt_bufnr)

                if vim.tbl_isempty(selections) then
                  local entry = action_state.get_selected_entry()
                  if entry then
                    selections = { entry }
                  end
                end

                for _, entry in ipairs(selections) do
                  vim.cmd("tabnew " .. vim.fn.fnameescape(entry.path))
                end

                vim.notify("✅ Opened " .. #selections .. " note(s).")
              end)

              return true
            end,
          })
        end,
        desc = "📂 Open Note(s)",
      },

      -- 2️⃣ 🌐 Preview Note
      {
        "<leader>Nb",
        function()
          local notes_dir = vim.fn.expand("~/Dev/Notes")
          require("telescope.builtin").find_files({
            prompt_title = "Preview Note",
            cwd = notes_dir,
            attach_mappings = function(_, map)
              local actions = require("telescope.actions")
              local action_state = require("telescope.actions.state")

              map("i", "<CR>", function(prompt_bufnr)
                local entry = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                if not entry then
                  vim.notify("❌ No note selected.", vim.log.levels.WARN)
                  return
                end

                vim.cmd("edit " .. vim.fn.fnameescape(entry.path))
                vim.cmd("MarkdownPreview")
                vim.notify("🌐 Previewing: " .. vim.fn.fnamemodify(entry.path, ":t"))
              end)

              return true
            end,
          })
        end,
        desc = "🌐 Preview Note In Browser",
      },

      -- 3️⃣ 📄 Create Note (with link prompt)
      {
        "<leader>Nc",
        function()
          local notes_dir = vim.fn.expand("~/Dev/Notes")
          vim.ui.input({ prompt = "Enter new note name:" }, function(input)
            if not (input and #input > 0) then
              vim.notify("❌ No note name provided.", vim.log.levels.WARN)
              return
            end

            local clean_name = input:gsub("%s+", "_"):lower()
            local ts_file = os.date("%d-%m-%Y_%H-%M-%S")
            local ts_human = os.date("%d-%m-%Y %H:%M:%S [%Z]")
            local filename = notes_dir .. "/" .. clean_name .. "_" .. ts_file .. ".md"
            vim.cmd("edit " .. vim.fn.fnameescape(filename))

            local lines = {
              "# 📝 **[" .. input .. "]**",
              "_____________________________",
              "⏰ *Created: " .. ts_human .. "*",
              "✍️ *Last Modified: " .. ts_human .. "*",
              "_____________________________",
              "## 🔗 **Linked Notes:**",
              "*(none yet)*",
              "_____________________________",
              "## 📚 **References / Resources:**",
              "- [Link to article](https://example.com)",
              "_____________________________",
              "### 🗒️ **Tasks / To-Do:**",
              "- [ ] Task 1...",
              "_____________________________",
              "#### ✨ **Your Notes Here:**",
              "- ...",
            }
            vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

            -- Auto-update Last Modified
            vim.api.nvim_create_autocmd("BufWritePost", {
              buffer = 0,
              callback = function()
                local stat = vim.loop.fs_stat(filename)
                if stat then
                  local mod_ts = os.date("%d-%m-%Y %H:%M:%S [%Z]", stat.mtime.sec)
                  local total = vim.api.nvim_buf_line_count(0)
                  for i = 1, total do
                    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
                    if line:match("^✍️ %*Last Modified:") then
                      vim.api.nvim_buf_set_lines(0, i - 1, i, false, { "✍️ *Last Modified: " .. mod_ts .. "*" })
                      break
                    end
                  end
                end
              end,
            })

            vim.cmd("write")
            vim.notify("✅ Note created.")

            -- Ask if user wants to link other notes
            vim.ui.select({ "Yes", "No" }, { prompt = "Link other notes?" }, function(choice)
              if choice == "Yes" then
                require("telescope.builtin").find_files({
                  prompt_title = "Select Notes to Link",
                  cwd = notes_dir,
                  attach_mappings = function(_, map)
                    local actions = require("telescope.actions")
                    local action_state = require("telescope.actions.state")

                    map("i", "<Tab>", actions.toggle_selection)
                    map("n", "<Tab>", actions.toggle_selection)

                    map("i", "<CR>", function(prompt_bufnr)
                      local picker = action_state.get_current_picker(prompt_bufnr)
                      local selections = picker:get_multi_selection()
                      actions.close(prompt_bufnr)

                      if vim.tbl_isempty(selections) then
                        vim.notify("ℹ️ No notes linked.")
                        return
                      end

                      local links = {}
                      for _, entry in ipairs(selections) do
                        table.insert(
                          links,
                          "- [" .. vim.fn.fnamemodify(entry.path, ":t:r") .. "](" .. entry.path .. ")"
                        )
                      end

                      local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                      for i, line in ipairs(buf_lines) do
                        if line:match("^## 🔗 %*%*Linked Notes:%*%*") then
                          if buf_lines[i + 1] and buf_lines[i + 1]:match("%(none yet%)") then
                            table.remove(buf_lines, i + 1)
                          end
                          for j, l in ipairs(links) do
                            table.insert(buf_lines, i + j, l)
                          end
                          break
                        end
                      end

                      vim.api.nvim_buf_set_lines(0, 0, -1, false, buf_lines)
                      vim.cmd("write")
                      vim.notify("🔗 Linked " .. #links .. " note(s).")
                    end)

                    return true
                  end,
                })
              else
                vim.notify("ℹ️ No links added.")
              end
            end)
          end)
        end,
        desc = "📄 Create New Note",
      },

      -- 4️⃣ ✏️ Rename Note
      {
        "<leader>Nr",
        function()
          local notes_dir = vim.fn.expand("~/Dev/Notes")
          require("telescope.builtin").find_files({
            prompt_title = "Rename Note",
            cwd = notes_dir,
            attach_mappings = function(_, map)
              local actions = require("telescope.actions")
              local action_state = require("telescope.actions.state")

              map("i", "<CR>", function(prompt_bufnr)
                local entry = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if entry then
                  vim.ui.input({
                    prompt = "New name:",
                    default = vim.fn.fnamemodify(entry.path, ":t:r"),
                  }, function(new_name)
                    if new_name and #new_name > 0 then
                      local clean = new_name:gsub("%s+", "_"):lower()
                      local ts = os.date("%d-%m-%Y_%H-%M-%S")
                      local new_path = notes_dir .. "/" .. clean .. "_" .. ts .. ".md"
                      local ok, err = vim.loop.fs_rename(entry.path, new_path)
                      if not ok then
                        vim.notify("❌ Rename failed: " .. err, vim.log.levels.ERROR)
                        return
                      end
                      vim.cmd("edit " .. vim.fn.fnameescape(new_path))
                      vim.notify("✅ Renamed to " .. new_name)
                    else
                      vim.notify("❌ Rename aborted.", vim.log.levels.WARN)
                    end
                  end)
                end
              end)
              return true
            end,
          })
        end,
        desc = "✏️ Rename Note",
      },

      -- 5️⃣ 🗑️ Delete Note(s)
      {
        "<leader>Nd",
        function()
          local notes_dir = vim.fn.expand("~/Dev/Notes")
          require("telescope.builtin").find_files({
            prompt_title = "Delete Note(s)",
            cwd = notes_dir,
            attach_mappings = function(_, map)
              local actions = require("telescope.actions")
              local action_state = require("telescope.actions.state")

              map("i", "<Tab>", actions.toggle_selection)
              map("n", "<Tab>", actions.toggle_selection)

              map("i", "<CR>", function(prompt_bufnr)
                local picker = action_state.get_current_picker(prompt_bufnr)
                local selections = picker:get_multi_selection()
                actions.close(prompt_bufnr)
                if vim.tbl_isempty(selections) then
                  selections = { action_state.get_selected_entry() }
                end

                local files = {}
                for _, entry in ipairs(selections) do
                  table.insert(files, entry.path)
                end

                vim.ui.select({ "Yes", "No" }, { prompt = "Delete " .. #files .. " file(s)?" }, function(choice)
                  if choice == "Yes" then
                    for _, file in ipairs(files) do
                      local ok, err = os.remove(file)
                      if not ok then
                        vim.notify("❌ Failed to delete: " .. err, vim.log.levels.ERROR)
                      else
                        vim.notify("✅ Deleted: " .. vim.fn.fnamemodify(file, ":t"))
                      end
                    end
                  else
                    vim.notify("❌ Deletion cancelled.")
                  end
                end)
              end)

              return true
            end,
          })
        end,
        desc = "🗑️ Delete Note(s)",
      },

      -- 6️⃣ 📝 Git Commit
      {
        "<leader>Ng",
        function()
          local notes_dir = vim.fn.expand("~/Dev/Notes")
          vim.ui.input({ prompt = "Commit Message:" }, function(msg)
            if not (msg and #msg > 0) then
              vim.notify("❌ Empty commit message.", vim.log.levels.WARN)
              return
            end
            vim.system({ "git", "-C", notes_dir, "add", "." }, {}, function()
              vim.system({ "git", "-C", notes_dir, "commit", "-m", msg }, {}, function()
                vim.notify("✅ Committed: " .. msg)
              end)
            end)
          end)
        end,
        desc = "📝 Git Commit Changes",
      },

      -- 7️⃣ 🚀 Git Push (floating terminal)
      {
        "<leader>Np",
        function()
          local notes_dir = vim.fn.expand("~/Dev/Notes")

          local width = math.floor(vim.o.columns * 0.6)
          local height = math.floor(vim.o.lines * 0.3)
          local row = math.floor((vim.o.lines - height) / 2 - 1)
          local col = math.floor((vim.o.columns - width) / 2)

          local buf = vim.api.nvim_create_buf(false, true)
          local win = vim.api.nvim_open_win(buf, true, {
            relative = "editor",
            width = width,
            height = height,
            row = row,
            col = col,
            style = "minimal",
            border = "rounded",
          })

          vim.fn.termopen({ "git", "-C", notes_dir, "push", "origin", "main" }, {
            on_exit = function(_, exit_code, _)
              vim.schedule(function()
                if exit_code == 0 then
                  vim.notify("✅ Git push succeeded!", vim.log.levels.INFO)
                else
                  vim.notify("❌ Git push failed!", vim.log.levels.ERROR)
                end
                if vim.api.nvim_win_is_valid(win) then
                  vim.api.nvim_win_close(win, true)
                end
              end)
            end,
          })

          vim.api.nvim_set_current_win(win)
          vim.cmd("startinsert")
        end,
        desc = "🚀 Git Push to GitHub",
      },
    },
  },
}
