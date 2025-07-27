require("base64")

local function send_kgp_msg(control, payload)
	local msg = string.format("\x1B_G%s;%s\x1B\\", control, payload)
	-- print("Msg: " .. msg)
	io.write(msg)
end

local function clear_imgs()
	send_kgp_msg("a=d", "")
end

local function move_cursor(line, col)
	io.write(string.format("\x1B[%d;%dH", line, col))
end

function show_image(lines, cols, path)
	send_kgp_msg(string.format("f=100,t=f,a=T,r=1,C=1,Y=%d,X=%d", lines, cols), enc(path))
end

-- :drgn_0_0_256:

local emoji_regex = ":drgn_[a-zA-Z0-9_\\-]\\+:"
local conceal_cmd = 'syntax match myConceal "' .. emoji_regex .. '" conceal'
vim.api.nvim_create_autocmd(
	{ "VimEnter", "BufWritePost", "WinScrolled" },
	{ -- FIXME: stuff gets weird with WinScrolled; must be because we call move_cursor inside here
		callback = function(ev)
			-- print(vim.inspect(ev))
			if ev.event == "WinScrolled" then
				if vim.v.event.all.height ~= 0 or vim.v.event.all.width ~= 0 then
					return
				end
				-- print(vim.inspect(vim.v.event))
			end
			clear_imgs()
			vim.cmd(conceal_cmd)
			local first_line = vim.fn.winsaveview().topline
			local matches =
				vim.fn.matchbufline(ev.buf, emoji_regex, first_line, first_line + vim.api.nvim_win_get_height(0))
			-- print(vim.inspect(matches))
			for _, match in ipairs(matches) do
				local text = match.text
				if string.gmatch(text, "^drgn.*$") then
					local path = "/home/jason/drgn_32/" .. string.sub(text, 2, #text - 1) .. ".png"
					-- print(path .. " exists!")
					local abs_pos = vim.fn.screenpos(0, match.lnum, match.byteidx)
					move_cursor(abs_pos.row, abs_pos.col)
					show_image(0, 0, path)
					-- print("Image sent!")
				end
			end
		end,
	}
)

return {}
