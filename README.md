# Better Tasks

**Better Tasks** is a lightweight, modular Neovim plugin for managing Markdown-based task lists across your notes, journals, or project files. It adds intuitive task management commands, persistent storage, status highlighting, and upcoming fuzzy-finding and popup UIs.

## ✨ Features

- 📋 Create new tasks with due dates, categories, and statuses in your current buffer _and_ automatically in your master open tasks list
- ✅ Mark tasks as done and automatically archive them
- 📚 Sort tasks in current buffer with all done tasks on top, open tasks on bottom, with option to sort via due date or status
- 🗂️ Custom categories and statuses with persistent JSON storage
- 🧠 Virtual text highlighting for status, category, and due date
- 📅 Popup prompt to edit status and due date inline
- 📁 Archive completed tasks by date and source automatically
- 📝 Format tasks like a table view in current buffer
- 🔍 Telescope and FZF integration (on roadmap)

---

## 📦 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return
{
  "MistbornOne/better-tasks.nvim",
  config = function()
    require("better-tasks").setup()
  end,
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use({
  "MistbornOne/better-tasks.nvim",
  config = function()
    require("better-tasks").setup()
  end,
})

```

Using [vim-plug](https://github.com/junegunn/vim-plug)

```lua
Plug 'MistbornOne/better-tasks.nvim'

```

Then in your Lua config (after plugins are loaded):

```lua
require("better-tasks").setup()

```

---

## ⚙️ Configuration

```lua
require("better-tasks").setup({
  master_task_file = "~/Tasks/Master.md", -- replace with your path
  archive_file = "~/Tasks/Archive.md", -- replace with your path

  options = {
    show_notifications = true,
    categories = { "Life", "Work", "Coding" },
    statuses = {
      ["TODO"] = "🆕",
      ["In Progress"] = "🌱",
      ["Stalled"] = "🛑",
      ["Cancel"] = "🚫",
      ["Done"] = "✅",
    },
  }
})
```

---

## 👨🏼‍💻 Usage

**Keymaps (Defaults)**

| Mapping       | Action                    |
| ------------- | ------------------------- |
| `<leader>tn`  | Insert new task           |
| `<leader>td`  | Mark current task as done |
| `<leader>tt`  | Change status via popup   |
| `<leader>tw`  | Change due date via popup |
| `<leader>ss`  | Sort open tasks by status |
| `<leader>sd`  | Sort open tasks by date   |
| `<leader>tm`  | View Master List (Popup)  |
| `<leader>ta`  | View Archive List (Popup) |
| `<leader>fmt` | Format As Table in Buffer |

---

## 💡 Task Structure

```markdown
- [x] Dot Files Setup | 📅 05-16-2025 | 🏷️ Coding | ✅ Done
- [ ] Try Better-Tasks.nvim | 📅 05-16-2025 | 🏷️ Life | 🆕 TODO
- [ ] Neovim Perfection | 📅 05-16-2025 | 🏷️ Coding | 🌱 In Progress
```

---

## 🔧 Roadmap

1. Telescope/FZF Integration
2. De-dupe enhancements
3. Task structure enhancements

---

## 💪🏼 Contribute

Feel free to open an issue or PR! Feature requests and bug reports are welcome.

---

📝 License

[MIT](https://github.com/MistbornOne/better-tasks.nvim/blob/main/LICENSE) © Ian Watkins
