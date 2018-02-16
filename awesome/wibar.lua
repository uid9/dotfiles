-- {{{ Wibar

-- Spacer
spacer = wibox.widget.textbox()
spacer:set_text(" ")

-- Create a textclock widget
myclockicon = wibox.widget.textbox()
myclockicon:set_markup("<span font='xbmicons' size='small'>&#xe011;</span> ")
mytextclock = wibox.widget.textclock("%I:%M%p", 10)
mytextclock_t = awful.tooltip({ objects = { mytextclock, myclockicon },
                                timer_function = function() return os.date("%a %b %d" ) end })

-- Battery widget
mybatt = wibox.widget.textbox()
mybatt_i = wibox.widget.textbox()
mybatt_t = awful.tooltip({ objects = { mybatt, mybatt_i } })
mybatt_timer = gears.timer({ timeout = 3 })
mybatt_timer:connect_signal("timeout", function() mybatt_update() end)
mybatt_timer:start()

function mybatt_update()
    local name = "BAT1"
    local path = "/sys/class/power_supply/" .. name .. "/"
    local stat = readfile(path .. "status")
    local full = readfile(path .. "energy_full")
    local curr = readfile(path .. "energy_now")
    local rate = readfile(path .. "power_now")
    local percent = math.min(math.floor(curr / full * 100), 100)
    local time = ""
    local timeleft = nil
    local tt = ""
    if stat == "Charged" or stat == "Full" or stat == "Unknown" then
        mybatt_i:set_markup("<span font='xbmicons' size='small'>&#xe00e;</span> ")
        tt = "Charged"
    end
    if stat == "Discharging" and rate ~= 0 then
        timeleft = curr / rate
        if percent > 75 then
            mybatt_i:set_markup("<span font='xbmicons' size='small'>&#xe00d;</span> ")
        elseif percent > 45 then
            mybatt_i:set_markup("<span font='xbmicons' size='small'>&#xe00c;</span> ")
        elseif percent > 15 then
            mybatt_i:set_markup("<span font='xbmicons' size='small'>&#xe00b;</span> ")
        else
            mybatt_i:set_markup("<span font='xbmicons' size='small' color='red'>&#xe00b;</span> ")
        end
        if percent < 10 then
            naughty.notify({text = "\n      BATTERY LOW!!!", fg = "white", bg = "dark red", timeout = 2, height = 60, width = 190, replaces_id = 0})
        end
    elseif stat == "Charging" and rate ~= 0 then
        timeleft = ((full - curr)  / rate)
        mybatt_i:set_markup("<span font='xbmicons' size='small'>&#xe00f;</span> ")
    end
    if timeleft ~= nil and timeleft ~= math.huge then
        local hoursleft   = math.floor(timeleft)
        local minutesleft = math.floor((timeleft - hoursleft) * 60 )
        time = string.format("(%02d:%02d)", hoursleft, minutesleft)
        tt = string.format("%s : %d%%", stat, percent)
    end
    mybatt:set_text(time)
    mybatt_t:set_text(tt)
end

mybatt_update()

-- Wifi widget
mywifi = wibox.widget.textbox()
mywifi_n = "wlp4s0"
mywifi_t = awful.tooltip({ objects = { mywifi }, timer_function = function() return mywifi_tt(mywifi_n) end })
mywifi_timer = gears.timer({ timeout = 3 })
mywifi_timer:connect_signal("timeout", function() mywifi_update(mywifi_n) end)
mywifi_timer:start()

function mywifi_tt(name)
    local t = "<span font_weight='bold'>" .. name .. "</span>\n"
    local stat = readfile("/sys/class/net/" .. name .. "/operstate")
    if stat == "up" then
        t = t .. readexec("(iwconfig " .. name .. " && ifconfig " .. name .. ") | \
                           egrep 'IEEE|Bit Rate|Power|Link Quality|flags|inet |RX packets|TX packets' | \
                           sed 's/" .. name .. ":*//;s/^\\s*//;s/[<>]/ /g'"):gsub("\n$", "")
    else
        t = t .. "Not connected"
    end
    return t
end

function mywifi_update(name)
    local stat = readfile("/sys/class/net/" .. name .. "/operstate")
    if stat == "up" then
        local s = readexec("grep " .. name .. " /proc/net/wireless")
        local lq = tonumber(s:match(name..": %d+%s+(%d+)"))
        if lq > 47 then
            mywifi:set_markup("<span font='xbmicons' size='small' color='cyan'>&#xe016;</span>")
        elseif lq > 24 then
            mywifi:set_markup("<span font='xbmicons' size='small' color='orange'>&#xe016;</span>")
        else
            mywifi:set_markup("<span font='xbmicons' size='small' color='red'>&#xe016;</span>")
        end
    else
        mywifi:set_markup("<span font='xbmicons' size='small'>&#xe016;</span>")
    end
end

mywifi_update(mywifi_n)

-- Ethernet widget
myen = wibox.widget.textbox()
myen_n = "enp0s31f6"
myen_t = awful.tooltip({ objects = { myen }, timer_function = function() return myen_tt(myen_n) end })
myen_timer = gears.timer({ timeout = 3 })
myen_timer:connect_signal("timeout", function() myen_update(myen_n) end)
myen_timer:start()

function myen_tt(iface)
    local t = "<span font_weight='bold'>" .. iface .. "</span>\n"
    local stat = readfile("/sys/class/net/" .. iface .. "/operstate")
    if stat == "up" then
        t = t .. readexec("(ifconfig " .. iface .. ") | \
                           egrep 'flags|inet |RX packets|TX packets' | \
                           sed 's/" .. iface .. ":*//;s/^\\s*//;s/[<>]/ /g'"):gsub("\n$", "")
    else
        t = t .. "Not connected"
    end
    return t
end

function myen_update(name)
    local stat = readfile("/sys/class/net/" .. name .. "/operstate")
    if stat == "up" then
        myen:set_markup("<span font='xbmicons' size='small' color='#00ff00'>&#xe015;</span>")
    else
        myen:set_markup("<span font='xbmicons' size='small'>&#xe015;</span>")
    end
end

myen_update(myen_n)

-- Create a wibox for each screen and add it

local taglist_buttons = awful.util.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end 
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end 
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c) 
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end 
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c 
                                                  c:raise()
                                              end 
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

-- Statusbar icon
myicon = wibox.widget.imagebox()
myicon:set_image(beautiful.awesome_icon)

-- Restart to update screen changes
screen.connect_signal("removed", awesome.restart)
screen.connect_signal("added", awesome.restart)

mymon()

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    if s.outputs['eDP1'] or screen:count() == 1 then
        awful.tag({ "1", "2", "3", "4", "5", "6", "7" }, s, awful.layout.layouts[1])
    else
        awful.tag({ "8", "9", "10" }, s, awful.layout.layouts[1])
    end

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()

    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            myicon,
            s.mytaglist,
            s.mypromptbox,
            s.mylayoutbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            wibox.widget.systray(),
            spacer,
            myen,
            spacer,
            mywifi,
            spacer,
            mybatt_i,
            mybatt,
            spacer,
            myclockicon,
            mytextclock,
            spacer,
        },
    }
end)
-- }}}
