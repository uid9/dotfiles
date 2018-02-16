-- Monitor switcher

pri_mon = "eDP1"
mon_config_file = "/dev/shm/.mon_config.conf"
mon_config = readfile(mon_config_file)
if mon_config == nil then
    writefile(mon_config_file, "single")
end

mymon_timer = gears.timer({ timeout = 3 })
mymon_timer:connect_signal("timeout", function() mymon(nil) end)
mymon_timer:start()

function mymon(cycle)
    local sec_mon
    local sec_status
    local sec_enabled
    mon_config = readfile(mon_config_file)

    local dp = readfile("/sys/class/drm/card0-DP-1/status")
    local hdmi = readfile("/sys/class/drm/card0-HDMI-A-2/status")
    if dp == "connected" then
        sec_mon = "DP1"
        sec_status = "connected"
        sec_enabled = readfile("/sys/class/drm/card0-DP-1/enabled")
    elseif hdmi == "connected" then
        sec_mon = "HDMI2"
        sec_status = "connected"
        sec_enabled = readfile("/sys/class/drm/card0-HDMI-A-2/enabled")
    else
        sec_status = "disconnected"
    end

    local pri_enabled = readfile("/sys/class/drm/card0-eDP-1/enabled")
    if sec_status == "disconnected" and pri_enabled == "disabled" then os.execute("xrandr --auto") return end

    if pri_enabled == "enabled" and sec_enabled == "enabled" and mon_config == "single" then
        os.execute("xrandr --output " .. pri_mon .. " --off --output " .. sec_mon .. " --auto")
    end

    if sec_status == "connected" then
        if sec_enabled == "disabled" then
            if mon_config == "single" then
                os.execute("xrandr --output " .. pri_mon .. " --off --output " .. sec_mon .. " --auto")
            elseif mon_config == "extend" then
                os.execute("xrandr --output " .. pri_mon .. " --auto --output " .. sec_mon .. " --right-of " .. pri_mon)
            elseif mon_config == "clone" then
                os.execute("xrandr --output " .. pri_mon .. " --auto --output " .. sec_mon .. " --same-as " .. pri_mon)
            end
        end
        if cycle == true then
            if mon_config == "single" then
                os.execute("xrandr --output " .. pri_mon .. " --auto --output " .. sec_mon .. " --right-of " .. pri_mon)
                writefile(mon_config_file, "extend")
            elseif mon_config == "extend" then
                os.execute("xrandr --output " .. pri_mon .. " --auto --output " .. sec_mon .. " --same-as " .. pri_mon)
                writefile(mon_config_file, "clone")
            elseif mon_config == "clone" then
                os.execute("xrandr --output " .. pri_mon .. " --off --output " .. sec_mon .. " --auto")
                writefile(mon_config_file, "single")
            end
        end
    end

end
