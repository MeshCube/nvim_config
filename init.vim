call plug#begin()
Plug 'morhetz/gruvbox'

Plug 'mfussenegger/nvim-dap'
Plug 'nvim-neotest/nvim-nio'
Plug 'rcarriga/nvim-dap-ui'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'theHamsta/nvim-dap-virtual-text'

Plug 'preservim/nerdtree'

"Plug 'nvim-neo-tree/neo-tree.nvim
"Plug 'puremourning/vimspector'

call plug#end()

set number
colorscheme gruvbox
set background=dark
"let g:vimspector_enable_mappings = 'HUMAN'
"packadd! vimspector

nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>

autocmd VimEnter * NERDTree | wincmd p
let g:NERDTreeWinSize = 25
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | call feedkeys(":quit\<CR>:\<BS>") | endif

lua << EOF

require("nvim-dap-virtual-text").setup({})
vim.g.dap_virtual_text = true

local dap, dapui = require("dap"), require("dapui")
dapui.setup({})

dap.listeners.before.attach.dapui_config = function()
  dapui.open()
    if vim.fn.exists("g:NERDTree") then
    -- Закрываем `NERDTree`, если он открыт
    vim.cmd("NERDTreeClose")
  end
end
dap.listeners.before.launch.dapui_config = function()
  dapui.open()
  if vim.fn.exists("g:NERDTree") then
    -- Закрываем `NERDTree`, если он открыт
    vim.cmd("NERDTreeClose")
  end
end
dap.listeners.before.event_terminated.dapui_config = function()
  dapui.close()
  if vim.fn.exists("g:NERDTree") then
    -- Открываем `NERDTree` с размером 25
    vim.cmd("NERDTree | wincmd p")
    vim.cmd("let g:NERDTreeWinSize = 25")
  end
end
dap.listeners.before.event_exited.dapui_config = function()
  dapui.close()
  if vim.fn.exists("g:NERDTree") then
    -- Открываем `NERDTree` с размером 25
    vim.cmd("NERDTree | wincmd p")
    vim.cmd("let g:NERDTreeWinSize = 25")
  end
end

local dap = require("dap")
dap.adapters.gdb = {
  type = "executable",
  command = "gdb",
  args = { "--interpreter=dap", "--eval-command", "set print pretty on" }
}

dap.configurations.c = {
  {
    name = "Launch",
    type = "gdb",
    request = "launch",
    command = "mkdir a",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = "${workspaceFolder}",
    stopAtBeginningOfMainSubprogram = false,
  },
}

dap.configurations.cpp = dap.configurations.c

dap.adapters.python = function(cb, config)
  if config.request == 'attach' then
    ---@diagnostic disable-next-line: undefined-field
    local port = (config.connect or config).port
    ---@diagnostic disable-next-line: undefined-field
    local host = (config.connect or config).host or '127.0.0.1'
    cb({
      type = 'server',
      port = assert(port, '`connect.port` is required for a python `attach` configuration'),
      host = host,
      options = {
        source_filetype = 'python',
      },
    })
  else
    cb({
      type = 'executable',
      command = 'python',
      args = { '-m', 'debugpy.adapter' },
      options = {
        source_filetype = 'python',
      },
    })
  end
end

dap.configurations.python = {
  {
    type = 'python';
    request = 'launch';
    name = "Launch file";

    program = "${file}";
    pythonPath = function()
      local cwd = vim.fn.getcwd()
      if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
        return cwd .. '/venv/bin/python'
      elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
        return cwd .. '/.venv/bin/python'
      else
        return '/usr/bin/python'
      end
    end;
  },
}

-- Custom keybindings (Optional)
vim.api.nvim_set_keymap('n', 'db', ':lua require("dap").toggle_breakpoint()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'dc', ':lua require("dap").continue()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'dt', ':lua require("dap").terminate()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'do', ':lua require("dap").step_over()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'di', ':lua require("dap").step_into()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'du', ':lua require("dap").step_out()<CR>', { noremap = true, silent = true })

EOF
