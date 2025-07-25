# Emoji.nvim

- so neofox can watch you code :3

## Requirements

- `conceallevel` must be greater than or equal to 2
- Note: only pngs are supported right now
- The kitty graphics protocol currently doesn't support scaling down images, which means you'll have to do it yourself. Below is a BASH command that does this:

```sh
mkdir -p drgn_32 && for img in drgn/*.png; do img="${img#*/}"; convert -resize 32X32 "drgn/$img" "drgn_32/$img"; done
```

This will create new 32x32 versions of all pngs in `drgn/` in the folder `drgn_32`

## Setup

- Lazy.nvim

```lua
{
    "mageOfStructs/emoji.nvim",
 init = function()
  require("emoji")
 end,
}
```

## TODOS

- [ ] set custom emoji path
- [ ] completion
- [ ] fix alignment issues when combining them with text
