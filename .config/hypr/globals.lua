
--FIXME: Hyprland's automatically generated declarations don't populate dispatchers
Dsp = hl.dsp --[[@as VlkDspNamespace]]

---Shallow-copy a table
---@generic T: table
---@param t T
---@return T
function Tablecpy(t)
	local out = {}
	for k, v in pairs(t) do
		out[k] = v
	end
	return out
end
