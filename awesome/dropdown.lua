-- Dropdown

local dropdown = {}

function spawn_or_toggle(prog, uname)

    local clients = client.get()
    for i, c in pairs(clients) do
        if c.instance == uname then
            cl = c
        end
    end

    if not cl then
        spawn = function(c)
            c.floating = true
            c.skip_taskbar = false
            c:raise()
            --client.focus = c
            --client.disconnect_signal("manage", spawn)
        end
        client.connect_signal("manage", spawn)
        client.connect_signal("unmanage", function() cl = nil end)
        awful.spawn(prog)
    else
        c = cl
        if c:isvisible() == false then c.hidden = true
            c:move_to_tag(awful.screen.focused().selected_tag)
        end 
        if c.hidden or (client.focus.window ~= c.window) then
            c.hidden = false
            c:raise()
            client.focus = c 
        else
            c.hidden = true
            local ctags = c:tags()
            for i, t in pairs(ctags) do
                ctags[i] = nil 
            end 
            c:tags(ctags)
        end
    end
end

return setmetatable(dropdown, { __call = function(_, ...) return spawn_or_toggle(...) end })
