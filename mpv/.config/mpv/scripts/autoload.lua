-- autoload.lua (configurable, video-only by default)
-- Based on official mpv autoload script, with config + image exclusion
--
-- Supports the following options via script-opts/autoload.conf:
--   enable_videos=yes|no       (default: yes)
--   enable_audio=yes|no        (default: yes)
--   enable_images=yes|no       (default: no)
--   max_entries=number         (default: 5000)
--   extensions=comma-separated list (optional override)

local utils = require 'mp.utils'
local msg = require 'mp.msg'
local opt = require 'mp.options'

local o = {
    enable_videos = true,
    enable_audio = true,
    enable_images = false,
    max_entries = 5000,
    extensions = ""
}

opt.read_options(o, "autoload")

local function split_path(str)
    return str:match("^(.-)[\\/]?([^\\/]-%.?([^%.\\/]*))$")
end

local function get_extension(path)
    return path:match("%.([^.]+)$")
end

local video_exts = {
    mkv=true, avi=true, mp4=true, mov=true, wmv=true,
    flv=true, webm=true, vob=true, ts=true, m4v=true,
    mpg=true, mpeg=true
}
local audio_exts = {
    mp3=true, wav=true, flac=true, ogg=true, m4a=true, opus=true, mka=true
}
local image_exts = {
    jpg=true, jpeg=true, png=true, bmp=true, gif=true,
    webp=true, avif=true, tiff=true, svg=true
}

-- Apply user-defined extensions (comma-separated list)
if o.extensions ~= "" then
    local custom = {}
    for ext in string.gmatch(o.extensions, "[^,%s]+") do
        custom[string.lower(ext)] = true
    end
    video_exts = custom
end

local allowed_exts = {}
if o.enable_videos then for k,v in pairs(video_exts) do allowed_exts[k]=v end end
if o.enable_audio then for k,v in pairs(audio_exts) do allowed_exts[k]=v end end
if o.enable_images then for k,v in pairs(image_exts) do allowed_exts[k]=v end end

local autoloaded = false

local function compare(a, b)
    return string.lower(a) < string.lower(b)
end

local function add_files(files)
    for _, f in ipairs(files) do
        mp.commandv("loadfile", f, "append")
    end
end

local function find_and_append()
    if autoloaded then return end
    autoloaded = true

    local path = mp.get_property("path", "")
    if not path or #path == 0 then return end

    local dir, filename = split_path(path)
    if not dir or dir == "" then dir = "." end

    local res = utils.readdir(dir, "files")
    if not res then
        msg.warn("Could not read directory:", dir)
        return
    end

    local current_ext = string.lower(get_extension(filename) or "")
    if not allowed_exts[current_ext] then
        msg.info("Not a supported file type for autoloading:", current_ext)
        return
    end

    local files = {}
    for _, f in ipairs(res) do
        local ext = string.lower(get_extension(f) or "")
        if allowed_exts[ext] then
            table.insert(files, utils.join_path(dir, f))
        end
    end

    table.sort(files, compare)

    local index = nil
    for i, f in ipairs(files) do
        if f == path then
            index = i
            break
        end
    end
    if not index then return end

    local prev = {}
    local nextf = {}

    for i = index - 1, 1, -1 do
        table.insert(prev, files[i])
        if #prev >= o.max_entries then break end
    end

    for i = index + 1, #files do
        table.insert(nextf, files[i])
        if #nextf >= o.max_entries then break end
    end

    for i = #prev, 1, -1 do
        mp.commandv("loadfile", prev[i], "append")
    end

    add_files(nextf)
    msg.info("Autoloaded " .. (#files - 1) .. " entries (configurable mode).")
end

mp.register_event("start-file", find_and_append)
