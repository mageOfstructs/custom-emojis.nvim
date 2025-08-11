# custom-emojis.nvim

![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/mageOfStructs/custom-emojis.nvim)
![GitHub language count](https://img.shields.io/github/languages/count/mageOfStructs/custom-emojis.nvim)


- so you can put neofoxxos in your code :3

## Requirements

- A terminal that implements the Kitty Graphics Protocol (e.g. kitty)
- `conceallevel` must be greater than or equal to 2
- Note: only pngs are supported right now
- The kitty graphics protocol currently doesn't support scaling down images, which means you'll have to do it yourself. Below is a BASH command (requires imagemagick) that does this:

```sh
mkdir -p drgn_32 && for img in drgn/*.png; do img="${img#*/}"; convert -resize 32X32 "drgn/$img" "drgn_32/$img"; done
```

This will create new 32x32 versions of all pngs in `drgn/` in the folder `drgn_32`

## Setup

- Lazy.nvim

```lua
{
    "mageOfStructs/emoji.nvim",
    opts = {
        -- Absolute Path to the folder containing the emojis, will be set to /home/$USER/.local/share/icons/emoji.nvim by default; no path expansions are supported right now
        -- emoji_path = "",
        
        -- Vim Regex for the emoji shortcodes
        -- emoji_regex = ":(drgn|neofox|wvrn)_[a-zA-Z0-9_\\-]\\+:",
    }
}
```

## TODOS

- [x] set custom emoji path
- [ ] completion
- [ ] fix alignment issues when combining them with text
