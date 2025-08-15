M = {}
local cur_img_id = 0
local imgs_ids = {}
local extmarks = {}

local plugin_ns = vim.api.nvim_create_namespace("CustomEmojis")
vim.api.nvim_set_hl(plugin_ns, "Alignment", { blend = 100, nocombine = false })
vim.api.nvim_set_hl_ns(plugin_ns)

local function send_kgp_msg(control, payload)
	local msg = string.format("\x1B_G%s;%s\x1B\\", control, payload)
	-- print("Msg: " .. msg)
	io.write(msg)
end

local function clear_imgs()
	for buf_id, _ in pairs(extmarks) do
		vim.api.nvim_buf_clear_namespace(buf_id, plugin_ns, 0, -1)
	end
	extmarks = {}
	imgs_ids = {}
	cur_img_id = 0
	send_kgp_msg("a=d", "")
end

local function delete_img(id)
	-- TODO: extmark
	table.remove(imgs_ids, id)
	send_kgp_msg(string.format("a=d,d=i,i=%d", id), "")
end

local function move_cursor(line, col)
	-- save cursor pos so neovim doesn't go insane
	io.write("\x1B[s")
	io.write(string.format("\x1B[%d;%dH", line, col))
end

local function restore_cursor()
	io.write("\x1B[u")
end

function M.show_image(lines, cols, path)
	send_kgp_msg(
		string.format("i=%d,q=2,f=100,t=f,a=T,r=1,C=1,Y=%d,X=%d", cur_img_id, lines, cols),
		vim.base64.encode(path)
	)
	cur_img_id = cur_img_id + 1
end

-- :drgn_0_0:

-- print(vim.inspect(vim.api.nvim_get_hl(plugin_ns, { name = "Alignment" })))

local function render_window(win_id, opts)
	local buf_id = vim.api.nvim_win_get_buf(win_id)
	local conceal_cmd = 'syntax match myConceal "' .. opts.emoji_regex .. '" conceal'
	-- vim.cmd(conceal_cmd)
	local first_line = vim.fn.winsaveview().topline
	local matches =
		vim.fn.matchbufline(buf_id, opts.emoji_regex, first_line, first_line + vim.api.nvim_win_get_height(0))
	local line_emojis_offsets = {}
	for _, match in ipairs(matches) do
		local text = match.text
		if string.gmatch(text, opts.emoji_regex) then
			-- print(vim.inspect({ row = match.lnum, col = match.byteidx, end_col = match.byteidx + #text }))
			-- vim.api.nvim_buf_set_extmark(buf_id, plugin_ns, match.lnum - 1, match.byteidx,
			--   { end_col = match.byteidx + #text, hl_group = "Conceal", strict = true, conceal = "" })
			-- print(match.lnum .. "/" .. match.byteidx)
			extmark_id = vim.api.nvim_buf_set_extmark(buf_id, plugin_ns, match.lnum - 1, match.byteidx, {
				end_col = match.byteidx + #text,
				strict = true,
				virt_text_pos = "inline",
				virt_text = { { "  ", "" } },
				virt_text_hide = true,
				-- hl_mode = "blend",
				conceal = "",
			})
			if line_emojis_offsets[match.lnum] == nil then
				line_emojis_offsets[match.lnum] = 0
			end

			if extmarks[buf_id] == nil then
				extmarks[buf_id] = {}
			end
			if extmarks[buf_id][match.lnum] == nil then
				extmarks[buf_id][match.lnum] = { extmark_id }
			else
				table.insert(extmarks[buf_id][match.lnum], extmark_id)
			end

			local path = opts.emoji_path .. string.sub(text, 2, #text - 1) .. ".png"

			if imgs_ids[win_id] == nil then
				imgs_ids[win_id] = {}
			end
			imgs_ids[win_id][#imgs_ids[win_id] + 1] = cur_img_id

			local abs_pos = vim.fn.screenpos(win_id, match.lnum, match.byteidx - line_emojis_offsets[match.lnum])
			move_cursor(abs_pos.row, abs_pos.col + 1)
			M.show_image(0, 0, path)
			restore_cursor()

			line_emojis_offsets[match.lnum] = line_emojis_offsets[match.lnum] + #match.text - 2
		end
	end
end

local function extract_window_ids(list, ret)
	for i = 1, #list do
		local v = list[i]
		if type(v) == "table" then
			extract_window_ids(v, ret)
		elseif type(v) == "number" then
			ret[#ret + 1] = v
		end
	end
end

local function getOS()
	local osname
	-- ask LuaJIT first
	if jit then
		return jit.os
	end

	-- Unix, Linux variants
	local fh, err = assert(io.popen("uname -o 2>/dev/null", "r"))
	if fh then
		osname = fh:read()
	end

	return osname or "Windows"
end

function M.setup(opts)
	if opts.emoji_path == nil then
		if getOS() ~= "Windows" then
			opts.emoji_path = "/home/" .. os.getenv("USER") .. "/.local/share/custom-emojis.nvim/"
		else
			opts.emoji_path = "C:\\Users\\" .. os.getenv("USERNAME") .. "\\AppData\\Local\\custom-emojis.nvim"
		end
	end
	if opts.emoji_regex == nil then
		opts.emoji_regex = ":\\(drgn_\\|neofox_\\|wvrn\\)[a-zA-Z0-9_\\-]*:"
	end

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre", "WinScrolled" }, {
		callback = function(ev)
			-- print(vim.inspect(ev))
			if ev.event == "WinScrolled" then
				-- TODO: this is bad
				if vim.v.event.all.height ~= 0 or vim.v.event.all.width ~= 0 then
					return
				end
				-- print(vim.inspect(vim.v.event))
			end
			clear_imgs()
			-- render_window(0, opts)
			local windows = vim.fn.winlayout()
			local window_ids = {}
			extract_window_ids(windows, window_ids)
			for i = 1, #window_ids do
				render_window(window_ids[i], opts)
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "QuitPre" }, {
		callback = function(ev)
			local win_id = vim.api.nvim_get_current_win()
			if imgs_ids[win_id] == nil then
				return
			end
			for i = 1, #imgs_ids[win_id] do
				delete_img(imgs_ids[win_id][i])
			end
		end,
	})
end

return M
