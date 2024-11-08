local util  = require "luci.util"
local jsonc = require "luci.jsonc"
local nixio = require "nixio"

local IStore = {}

IStore.blocks = function()
  local f = io.popen("lsblk -s -f -b -o NAME,FSSIZE,MOUNTPOINT --json", "r")
  local vals = {}
  if f then
    local ret = f:read("*all")
    f:close()
    local obj = jsonc.parse(ret)
    for _, val in pairs(obj["blockdevices"]) do
      local fsize = val["fssize"]
      if fsize ~= nil and string.len(fsize) > 10 and val["mountpoint"] then
        -- fsize > 1G
        vals[#vals+1] = val["mountpoint"]
      end
    end
  end
  return vals
end

IStore.default_image = function()
  local dockeramd64 = "registry.cn-shanghai.aliyuncs.com/nsp-prod-1/public1:lsy-iaas-amd64-latest"
  local dockerarm64 = "registry.cn-shanghai.aliyuncs.com/nsp-prod-1/public1:lsy-iaas-arm64-latest"
  if string.find(nixio.uname().machine, "x86_64") then
    return dockeramd64
  else
    return dockerarm64
  end
end

local random_str = function(t)
  math.randomseed(os.time())
  local s = "0123456789abcdefghijklmnopqrstuvwsyz"
  local value = ""
  for x = 1,t do
    local rand = math.random(#s)
    value = value .. string.sub(s, rand, rand)
  end
  return value
end

IStore.default_uid = function()
  local f = io.open("/sys/class/net/eth0/address", "r")
  if not f then
    f = io.open("/sys/class/net/br-lan/address", "r")
  end
  if not f then
    return random_str(16)
  end
  local ret = f:read("*all")
  f:close()
  return string.gsub(ret, "[ \r\n:]+", "") .. random_str(8)
end

return IStore

