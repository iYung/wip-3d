## Goal

Port the UTF-8 safe typewriter fix from `wip` (2D) to `wip-3d` (3D). The bug causes multi-byte UTF-8 characters in customer dialog text to be rendered as garbled output mid-reveal, because the typewriter effect slices the string at a raw byte index that may land inside a multi-byte sequence. The fix clamps the slice index to the nearest valid UTF-8 character boundary before calling `string.sub`.

## Affected files

- `lua/game/customer.lua` — line 270, where `string.sub(self._full_text, 1, self.reveal_index)` is called with no UTF-8 boundary check.

## What changes

Replace the single raw `string.sub` call at `customer.lua:270` with the UTF-8 safe version ported from `wip`:

```lua
local idx = self.reveal_index
while idx > 0 and (string.byte(self._full_text, idx) or 0) >= 0x80
              and (string.byte(self._full_text, idx) or 0) <  0xC0 do
    idx = idx - 1
end
if (string.byte(self._full_text, idx) or 0) >= 0xC0 then
    idx = idx - 1
end
local revealed = string.sub(self._full_text, 1, idx)
```

The logic walks `reveal_index` backward past any trailing continuation bytes (0x80–0xBF), then one more step backward if it lands on a leading byte (0xC0+), ensuring the slice never cuts inside a multi-byte sequence.

## What stays the same

- `self.reveal_index` is still incremented exactly as before — this fix only changes how the index is consumed at draw time, not how it advances.
- All other draw logic in `Customer:draw` (box sizing, positioning, font metrics, 9-slice bubble, tail sprite) is unchanged.
- No other files are touched.

## Open questions

None. This is a direct, isolated port of a known fix from `wip`. The algorithm, the affected file, and the exact insertion point are all confirmed.
