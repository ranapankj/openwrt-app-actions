
module("luci.controller.IStore", package.seeall)

function index()
  entry({"admin", "services", "IStore"}, alias("admin", "services", "IStore", "config"), _("BlueMountain Edge"), 30).dependent = true
  entry({"admin", "services", "IStore", "config"}, cbi("IStore"))
end
