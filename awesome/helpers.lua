-- {{{ Helper functions

function readfile(file, fmt)
    local f = io.open(file, "r")
    if f == nil then return nil end
    fmt = fmt or "*l"
    local content = f:read(fmt)
    f:close()
    return content
end

function writefile(file, content)
    local f = io.open(file, "w")
    if f == nil then return nil end
    f:write(content)
    f:close()
    return
end

function readexec(cmd, fmt)
    local f = io.popen(cmd)
    if f == nil then return nil end
    fmt = fmt or "*a"
    local content = f:read(fmt)
    f:close()
    return content
end
