# Upstream pins

Measured when this repo was first published.

| Piece | Pin |
| --- | --- |
| Matt Pocock skills | `mattpocock/skills` @ `49dd158d1076134a641b33efb035946536778336` |
| pstack | Cursor plugin `0.15.15`, already installed. Not forked. |
| cursor-team-kit | `1.2.0`, copied into the local Cursor plugins folder from `cursor/plugins`. |
| Herdr | `0.9.3` |

Install Matt again with:

```bash
npx skills@latest add mattpocock/skills -g -a cursor -a opencode -y --skill '*' --copy
```

Do not vendor these trees into this repo. This file is the pin.
