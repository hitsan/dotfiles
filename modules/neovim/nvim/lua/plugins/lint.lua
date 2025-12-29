return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

      -- Configure Verilator linter for SystemVerilog
      lint.linters.verilator = {
        cmd = "verilator",
        stdin = false,
        args = {
          "--lint-only",
          "-Wall",
          "--bbox-unsup", -- Don't warn about unsupported constructs in black-boxed modules
        },
        stream = "stderr",
        ignore_exitcode = true,
        parser = require("lint.parser").from_pattern(
          [[^%%(%w+)%-(%w+): ([^:]+):(%d+):(%d+): (.+)$]],
          { "severity", "code", "file", "lnum", "col", "message" },
          {
            Warning = vim.diagnostic.severity.WARN,
            Error = vim.diagnostic.severity.ERROR,
          },
          { ["source"] = "verilator" }
        ),
      }

      -- Set linters by filetype
      lint.linters_by_ft = {
        systemverilog = { "verilator" },
        verilog = { "verilator" },
      }

      -- Auto-lint on specific events
      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          -- Only lint if the linter is available for this filetype
          if lint.linters_by_ft[vim.bo.filetype] then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
