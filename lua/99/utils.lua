local M = {}

--- Generate a unique temp file path in the system temp directory
--- Using os.tmpname() ensures proper temp directory and unique filename
--- @return string
function M.random_file()
  -- Use system temp directory instead of cwd/tmp to avoid conflicts
  local tmpdir = vim.fn.stdpath("cache") or "/tmp"
  local timestamp = vim.uv.hrtime() -- nanosecond precision
  local random_part = math.floor(math.random() * 100000)
  return string.format("%s/99-output-%d-%d", tmpdir, timestamp, random_part)
end

return M
