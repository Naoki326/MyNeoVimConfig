return {
  "seblj/roslyn.nvim",
  ft = "cs", -- 只在打开 C# 文件时加载
  dependencies = {
    "mason-org/mason.nvim",
  },
  -- 延迟启动优化：在插件加载（打开 cs 文件）前跳过 roslyn.nvim 的 plugin/roslyn.lua
  -- 脚本（它会在打开 C# 文件时立即 vim.lsp.enable("roslyn")，拉起 dotnet Roslyn
  -- 服务器进程，阻塞启动约 300ms+）。改为按下 <leader>cl 或 :Roslyn target 时手动启动。
  -- init 钩子在 plugin/ 脚本之前执行，设置此变量即可阻止脚本体运行。
  init = function()
    vim.g.loaded_roslyn_plugin = true
  end,
  config = function()
    -- 延迟启动补充说明：nvim 0.12 的 enable() 在 did_filetype()==1 时会立即 doautoall
    -- 启动 client，在 config 里用 enable(name, false) 抵消已来不及；且 Windows 上
    -- stop 需要 force_stop。因此由上方 init 钩子跳过 plugin 脚本，
    -- 并在此手动注册其 autocmd（命令、sln 跟踪、source-generated 支持）。

    -- LSP 配置（cmd 等会由 nvim 从 roslyn.nvim 的 lsp/roslyn.lua 自动加载）
    vim.lsp.config("roslyn", {
      capabilities = require("blink.cmp").get_lsp_capabilities(),
      handlers = {
        ["activeProject/changed"] = function() end,
      },
      settings = {
        ["csharp|background_analysis"] = {
          dotnet_analyzer_diagnostics_scope = "openFiles",
          dotnet_compiler_diagnostics_scope = "openFiles",
        },
        ["csharp|inlay_hints"] = {
          csharp_enable_inlay_hints_for_implicit_object_creation = true,
          csharp_enable_inlay_hints_for_implicit_variable_types = true,
        },
        ["csharp|code_lens"] = {
          dotnet_enable_references_code_lens = true,
        },
      },
    })

    require("roslyn").setup({
      lock_target = true, -- 记住上次 :Roslyn target 选择的 .sln，避免每次弹窗
      extensions = {
        razor = { enabled = false }, -- 禁用 Razor 扩展，避免 --razorSourceGenerator 等参数不被当前版本 Roslyn 识别
      },
    })

    -- ===== 手动恢复 plugin/roslyn.lua 中除 vim.lsp.enable() 外的逻辑 =====
    local group = vim.api.nvim_create_augroup("roslyn.nvim", { clear = true })

    -- BufEnter 时更新当前 buffer 对应的 sln（plugin 脚本同款）
    vim.api.nvim_create_autocmd("BufEnter", {
      group = group,
      pattern = { "*.cs", "*.razor", "*.cshtml" },
      callback = function(args)
        local config = require("roslyn.config").get()
        local client = vim.lsp.get_clients({ name = "roslyn", bufnr = args.buf })[1]
        if client and not config.lock_target then
          vim.g.roslyn_nvim_selected_solution = require("roslyn.store").get(client.id)
        end
      end,
    })

    -- FileType cs 时创建 :Roslyn 命令（plugin 脚本同款）
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = { "cs", "razor" },
      callback = function()
        require("roslyn.commands").create_roslyn_commands()
      end,
    })

    -- BufReadCmd 支持 roslyn-source-generated:// 文件（plugin 脚本同款）
    vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
      group = group,
      pattern = "roslyn-source-generated://*",
      callback = function(args)
        vim.bo[args.buf].modifiable = true
        vim.bo[args.buf].swapfile = false
        vim.bo[args.buf].filetype = "cs"
        local client = vim.lsp.get_clients({ name = "roslyn", bufnr = args.buf })[1]
          or vim.lsp.get_clients({ name = "roslyn" })[1]
        if not client then
          vim.wait(5000, function()
            return next(vim.lsp.get_clients({ name = "roslyn", bufnr = args.buf })) ~= nil
          end)
          client = vim.lsp.get_clients({ name = "roslyn", bufnr = args.buf })[1]
        else
          vim.lsp.buf_attach_client(args.buf, client.id)
        end
        assert(client, "Must have a `roslyn` client to load roslyn source generated file")
        local content
        local function handler(err, result)
          assert(not err, vim.inspect(err))
          content = result.text or ""
          if content == vim.NIL then content = "" end
          local normalized = string.gsub(content, "\r\n", "\n")
          local source_lines = vim.split(normalized, "\n", { plain = true })
          vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, source_lines)
          vim.b[args.buf].resultId = result.resultId
          vim.bo[args.buf].modifiable = false
          vim.bo[args.buf].modified = false
        end
        local params = { textDocument = { uri = args.match }, resultId = nil }
        client:request("sourceGeneratedDocument/_roslyn_getText", params, handler, args.buf)
        vim.wait(1000, function() return content ~= nil end)
      end,
    })

    -- Roslyn 专属快捷键（buffer-local）。
    -- 注意：client 不再自动启动，LspAttach 不会触发，所以改为在 FileType cs 时注册。
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("roslyn-keymaps", { clear = true }),
      pattern = "cs",
      callback = function(ev)
        local map = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = "Roslyn: " .. desc })
        end

        -- 手动选择 .sln 目标（若 client 未启动，Roslyn target 会自行 vim.lsp.start）
        map("<leader>ct", function()
          vim.cmd("Roslyn target")
        end, "Select Solution Target")

        -- 启动/重启 Roslyn 分析
        map("<leader>cl", function()
          local clients = vim.lsp.get_clients({ name = "roslyn" })
          if #clients == 0 then
            vim.notify("Roslyn: no active client, starting...", vim.log.levels.INFO)
            vim.lsp.enable("roslyn")
            return
          end
          for _, c in ipairs(clients) do
            c:stop()
          end
          vim.notify("Roslyn: restarting analysis...", vim.log.levels.INFO)
          vim.defer_fn(function()
            vim.lsp.enable("roslyn")
          end, 1500)
        end, "Restart Analysis")
      end,
    })
  end,
}
