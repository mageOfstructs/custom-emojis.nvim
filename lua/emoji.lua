require("base64")

M = {}
local cur_img_id = 0
local imgs_ids = {}

local function send_kgp_msg(control, payload)
	local msg = string.format("\x1B_G%s;%s\x1B\\", control, payload)
	-- print("Msg: " .. msg)
	io.write(msg)
end

local function clear_imgs()
	imgs_ids = {}
	cur_img_id = 0
	send_kgp_msg("a=d", "")
end

local function delete_img(id)
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
	send_kgp_msg(string.format("i=%d,q=2,f=100,t=f,a=T,r=1,C=1,Y=%d,X=%d", cur_img_id, lines, cols), enc(path))
	cur_img_id = cur_img_id + 1
end

-- :drgn_0_0_256:

local function render_window(win_id, opts)
	local buf_id = vim.api.nvim_win_get_buf(win_id)
	local conceal_cmd = 'syntax match myConceal "' .. opts.emoji_regex .. '" conceal'
	vim.cmd(conceal_cmd)
	local first_line = vim.fn.winsaveview().topline
	local matches =
		vim.fn.matchbufline(buf_id, opts.emoji_regex, first_line, first_line + vim.api.nvim_win_get_height(0))
	-- print(vim.inspect(matches))
	for _, match in ipairs(matches) do
		local text = match.text
		if string.gmatch(text, "^drgn.*$") then
			local path = opts.emoji_path .. string.sub(text, 2, #text - 1) .. ".png"
			if imgs_ids[win_id] == nil then
				imgs_ids[win_id] = {}
			end
			imgs_ids[win_id][#imgs_ids[win_id] + 1] = cur_img_id
			local abs_pos = vim.fn.screenpos(win_id, match.lnum, match.byteidx)
			move_cursor(abs_pos.row, abs_pos.col)
			M.show_image(0, 0, path)
			restore_cursor()
			-- print("Image sent!")
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

function M.setup(opts)
	if opts.emoji_path == nil then
		opts.emoji_path = "/home/jason/drgn_32/"
	end
	if opts.emoji_regex == nil then
		opts.emoji_regex = ":drgn_[a-zA-Z0-9_\\-]\\+:"
	end

	vim.api.nvim_create_autocmd({ "VimEnter", "BufWritePost", "WinScrolled" }, {
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
