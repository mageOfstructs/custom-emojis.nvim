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
	-- io.write(string.format("\x1B_Gi=32,f=100,t=f,a=T,r=1,C=1,V=%d,H=%d;%s\x1B\\", cols, lines, enc(path)))
end

-- vim.api.nvim_create_autocmd({ "BufEnter", "VimEnter" }, {
-- 	callback = function(args)
-- 		show_image(30, 3, "/home/jason/drgn_32/drgn_0_0_256.png")
-- 	end,
-- })

-- :drgn_0_0_256:
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	callback = function(ev)
		clear_imgs()
		local matches = vim.fn.matchbufline(ev.buf, ":.\\+:", 1, "$")
		-- print(vim.inspect(matches))
		vim.cmd('syntax match myConceal ":.\\+:" conceal')
		for _, match in ipairs(matches) do
			local text = match.text
			if string.gmatch(text, "^drgn.*$") then
				local path = "/home/jason/drgn_32/" .. string.sub(text, 2, #text - 1) .. ".png"
				-- print(path .. " exists!")
				move_cursor(match.lnum, match.byteidx + 6) -- TODO: maybe not hardcode it
				show_image(0, 0, path)
				-- print("Image sent!")
			end
		end
	end,
})

return {}
