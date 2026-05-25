## UTF-8 Typewriter Checklist

- [x] Replace raw `string.sub` with UTF-8 boundary-safe version — `lua/game/customer.lua` — around line 270, replace the single line:

  ```lua
  local revealed = string.sub(self._full_text, 1, self.reveal_index)
  ```

  with the following block, which walks `reveal_index` backward past any trailing continuation bytes (0x80–0xBF) and then one further step if it lands on a leading byte (0xC0+), so the slice never cuts inside a multi-byte sequence:

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

  `self.reveal_index` is not changed — only the consumption of that index at draw time is affected. No other lines in the file or any other files are touched.
