local M = {
  transcript = {},
}

function M.add_message(role, content)
  table.insert(M.transcript, { role = role, content = content })
end

function M.get_transcript()
  return M.transcript
end

function M.reset()
  M.transcript = {}
end

return M
