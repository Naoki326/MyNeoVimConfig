-- 将 <path-to-im-select> 替换为实际路径，例如 "C:\\tools\\im-select.exe"
local im_select_path = vim.fn.expand("~/Tools/im_select.exe")
im_select_path = im_select_path:gsub("\\", "/")

-- 仅当在 Windows 系统且 im-select 可执行文件存在时才创建 autocommands
if vim.fn.has("win32") == 1 and vim.fn.executable(im_select_path) == 1 then
    print("hasIm_Select")
    local ime_autogroup = vim.api.nvim_create_augroup("ImeAutoGroup", { clear = true })

    vim.api.nvim_create_autocmd("InsertLeave", {
        group = ime_autogroup,
        callback = function()
            vim.cmd(":silent :!" .. im_select_path .. " 1033")
        end
    })

    vim.api.nvim_create_autocmd("InsertEnter", {
        group = ime_autogroup,
        callback = function()
            vim.cmd(":silent :!" .. im_select_path .. " 2052")
        end
    })
end

