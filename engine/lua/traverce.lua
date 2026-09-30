-- Traverce extensions for zapret2.
-- Loaded after zapret-lib.lua, zapret-antidpi.lua and zapret-auto.lua.

-- traverce_circular wraps the standard `circular` orchestrator and remembers
-- the strategy that is currently in use for every host key. Version 0.3 writes
-- a Traverce memo file, while still reading the pre-0.3 Prosvet memo on first
-- use so an upgrade can keep a strategy that already worked on this network.
--
-- arg: memo=<key> - memory file key, [A-Za-z0-9_-] only. usually a network id
-- all other args are passed to circular as is (fails, time, nld, ...)

local memo_tables = {}

local function memo_path(key)
	return writable_file_name("traverce-"..key..".memo")
end

local function legacy_memo_path(key)
	return writable_file_name("prosvet-"..key..".memo")
end

local function memo_load(key)
	local t = memo_tables[key]
	if t then return t end
	t = {}
	local f = io.open(memo_path(key), "rb")
	if not f then
		f = io.open(legacy_memo_path(key), "rb")
	end
	if f then
		for line in f:lines() do
			local host, n = string.match(line, "^(%S+)%s+(%d+)%s*$")
			if host then t[host] = tonumber(n) end
		end
		f:close()
	end
	memo_tables[key] = t
	return t
end

local function memo_save(key, t)
	local f = io.open(memo_path(key), "wb")
	if not f then
		DLOG_ERR("traverce: cannot write "..memo_path(key))
		return
	end
	for host, n in pairs(t) do
		f:write(host, " ", tostring(n), "\n")
	end
	f:close()
end

function traverce_circular(ctx, desync)
	local key = desync.arg.memo
	if not key or not string.match(key, "^[%w_-]+$") then
		key = "default"
	end
	local hostkey = desync.track and standard_hostkey(desync)
	local hrec = hostkey and automate_host_record(desync)
	local t = memo_load(key)
	if hrec and not hrec.nstrategy and t[hostkey] then
		hrec.nstrategy = t[hostkey]
	end

	local verdict = circular(ctx, desync)

	if hrec and hrec.nstrategy and t[hostkey] ~= hrec.nstrategy then
		t[hostkey] = hrec.nstrategy
		memo_save(key, t)
	end
	return verdict
end
