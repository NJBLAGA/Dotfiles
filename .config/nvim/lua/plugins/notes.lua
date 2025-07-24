return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        ["<leader>N"] = { name = "📝 Notes" },
        ["<leader>Nc"] = { desc = "Create New Note" },
        ["<leader>No"] = { desc = "Open Note(s)" },
        ["<leader>Nr"] = { desc = "Rename Note" },
        ["<leader>Nd"] = { desc = "Delete Note(s)" },
      },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>Nc",
        function()
          local notes_dir = vim.fn.expand("~/Dev/Notes")

          vim.ui.input({ prompt = "Enter new note name:" }, function(input)
            if not (input and #input > 0) then
              return
            end

            local filename = notes_dir .. "/" .. input .. ".md"
            vim.cmd("edit " .. vim.fn.fnameescape(filename))

            local creation_ts = os.date("%Y-%m-%d %H:%M:%S %Z")

            local lines = {
              "# 📝 " .. input,
              "",
              "--------",
              "",
              "⏰ Created: " .. creation_ts,
              "",
              "✍️ Last Modified: " .. creation_ts,
              "",
              "## Linked Notes:",
              "",
            }

            vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

            vim.api.nvim_create_autocmd("BufWritePost", {
              buffer = 0,
              callback = function()
                local stat = vim.loop.fs_stat(filename)
                if stat then
                  local mod_ts = os.date("%Y-%m-%d %H:%M:%S %Z", stat.mtime.sec)
                  local total_lines = vim.api.nvim_buf_line_count(0)
                  for i = 1, total_lines do
                    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
                    if line:match("^✍️ Last Modified:") then
                      vim.api.nvim_buf_set_lines(0, i - 1, i, false, { "✍️ Last Modified: " .. mod_ts })
                      break
                    end
                  end
                end
              end,
            })

            vim.ui.input({ prompt = "Link this note to other notes? (y/n): " }, function(answer)
              if answer and answer:lower():match("^y") then
                require("telescope.builtin").find_files({
                  prompt_title = "Select notes to link",
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

                      if selections and #selections > 0 then
                        local insert_lines = {}
                        for _, entry in ipairs(selections) do
                          local name = vim.fn.fnamemodify(entry.path, ":t:r")
                          local relative_path = "./" .. vim.fn.fnamemodify(entry.path, ":t")
                          table.insert(insert_lines, string.format("- 🔗 **[%s](%s)**", name, relative_path))
                        end

                        local insert_pos = 9
                        vim.api.nvim_buf_set_lines(0, insert_pos, insert_pos, false, insert_lines)

                        vim.cmd("write")
                        vim.notify("Linked " .. #insert_lines .. " note(s).")
                      else
                        vim.notify("No notes linked.", vim.log.levels.WARN)
                      end
                    end)

                    return true
                  end,
                })
              else
                vim.cmd("write")
              end
            end)
          end)
        end,
        desc = "Create New Note",
      },

      {
        "<leader>No",
        function()
          require("telescope.builtin").find_files({
            prompt_title = "Open Note",
            cwd = vim.fn.expand("~/Dev/Notes"),
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
                  vim.cmd("tabnew " .. vim.fn.fnameescape(entry.path))
                else
                  for _, entry in ipairs(selections) do
                    vim.cmd("tabnew " .. vim.fn.fnameescape(entry.path))
                  end
                end
              end)

              return true
            end,
          })
        end,
        desc = "Open Note(s)",
      },

      {
        "<leader>Nr",
        function()
          require("telescope.builtin").find_files({
            prompt_title = "Rename Note",
            cwd = vim.fn.expand("~/Dev/Notes"),
            attach_mappings = function(_, map)
              local actions = require("telescope.actions")
              local action_state = require("telescope.actions.state")

              map("i", "<CR>", function(prompt_bufnr)
                local entry = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if entry then
                  vim.ui.input({
                    prompt = "New name (no extension):",
                    default = vim.fn.fnamemodify(entry.path, ":t:r"),
                  }, function(new_name)
                    if new_name and #new_name > 0 then
                      local notes_dir = vim.fn.expand("~/Dev/Notes")
                      local old_path = entry.path
                      local new_path = notes_dir .. "/" .. new_name .. ".md"

                      -- Rename file on disk
                      local ok, err = vim.loop.fs_rename(old_path, new_path)
                      if not ok then
                        vim.notify("Rename failed: " .. err, vim.log.levels.ERROR)
                        return
                      end

                      -- Update H1 header in file content
                      local buf = vim.api.nvim_create_buf(false, true)
                      vim.cmd("edit " .. vim.fn.fnameescape(new_path))
                      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

                      if #lines > 0 then
                        -- Find line starting with # 📝 and replace name
                        for i, line in ipairs(lines) do
                          if line:match("^# 📝 ") then
                            lines[i] = "# 📝 " .. new_name
                            break
                          end
                        end
                      end

                      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
                      vim.cmd("write")

                      vim.notify("Renamed to " .. new_name)
                      vim.cmd("edit " .. vim.fn.fnameescape(new_path))
                    end
                  end)
                end
              end)

              return true
            end,
          })
        end,
        desc = "Rename Note",
      },

      {
        "<leader>Nd",
        function()
          require("telescope.builtin").find_files({
            prompt_title = "Delete Note(s)",
            cwd = vim.fn.expand("~/Dev/Notes"),
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

                local files_to_delete = {}
                for _, entry in ipairs(selections) do
                  table.insert(files_to_delete, entry.path)
                end

                vim.ui.select(
                  { "Yes", "No" },
                  { prompt = "Delete " .. #files_to_delete .. " file(s)?" },
                  function(choice)
                    if choice == "Yes" then
                      for _, file in ipairs(files_to_delete) do
                        local ok, err = os.remove(file)
                        if not ok then
                          vim.notify("Failed to delete: " .. err, vim.log.levels.ERROR)
                        else
                          vim.notify("Deleted: " .. vim.fn.fnamemodify(file, ":t"))
                        end
                      end
                    end
                  end
                )
              end)

              return true
            end,
          })
        end,
        desc = "Delete Note(s)",
      },
    },
  },
}
