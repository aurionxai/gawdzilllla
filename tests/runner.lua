-- tests/runner.lua
local R = {}
R._pass = 0
R._fail = 0

function R.test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    R._pass = R._pass + 1
    print("  ✓ " .. name)
  else
    R._fail = R._fail + 1
    print("  ✗ " .. name)
    print("    " .. tostring(err))
  end
end

function R.eq(a, b, label)
  if a ~= b then
    error((label and label .. ": " or "") .. "expected " .. tostring(b) .. ", got " .. tostring(a), 2)
  end
end

function R.approx(a, b, label)
  if math.abs(a - b) > 0.001 then
    error((label and label .. ": " or "") .. "expected ~" .. tostring(b) .. ", got " .. tostring(a), 2)
  end
end

function R.ok(v, label)
  if not v then error((label or "expected truthy"), 2) end
end

function R.notok(v, label)
  if v then error((label or "expected falsy"), 2) end
end

function R.summary()
  print(string.format("\n%d passed, %d failed", R._pass, R._fail))
  if R._fail > 0 then os.exit(1) end
end

return R
