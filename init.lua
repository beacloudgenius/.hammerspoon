--
-- Reloading of the config file
--

function reload_config(files)
    hs.reload()
end
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reload_config):start()
hs.alert.show("Config loaded")

--
-- Window Movement
--
-- CTRL + ALT + Left - Move current window to the left half of the screen.
-- CTRL + ALT + Right - Move current window to the right half of the screen.
-- CTRL + ALT + Up - Go "fullscreen".
-- CTRL + ALT + Down - Center window, covering 2/3 of screen size.
--

function move_window(direction)
    return function()
        local win      = hs.window.focusedWindow()
        local app      = win:application()
        local app_name = app:name()
        local f        = win:frame()
        local screen   = win:screen()
        local max      = screen:frame()

        if direction == "left" then
            if app_name == "Tweetbot" then
                f.x = max.x
            else
                f.x = max.x
                f.w = max.w / 2
            end
        elseif direction == "right" then
            if app_name == "Tweetbot" then
                f.x = max.x + (max.w - f.w)
            else
                f.x = max.x + (max.w / 2)
                f.w = max.w / 2
            end
        elseif direction == "up" then
            f.x = max.x
            f.w = max.w
        elseif direction == "down" then
            f.x = max.x + (max.w / 6)
            f.w = max.w * 2 / 3
        else
            hs.alert.show("move_window(): Freaky parameter received " .. direction)
        end

        f.y = max.y
        f.h = max.h
        win:setFrame(f, 0)
    end
end

local hyper = {"ctrl", "alt"}
hs.hotkey.bind(hyper, "Left", move_window("left"))
hs.hotkey.bind(hyper, "Right", move_window("right"))
hs.hotkey.bind(hyper, "Up", move_window("up"))
hs.hotkey.bind(hyper, "Down", move_window("down"))

--
-- Caffeine Replacement
--

local caffeine = hs.menubar.new()

function setCaffeineDisplay(state)
    if state then
        caffeine:setIcon(os.getenv("HOME") .. "/.hammerspoon/caffeine/active.png")
    else
        caffeine:setIcon(os.getenv("HOME") .. "/.hammerspoon/caffeine/inactive.png")
    end
end

function caffeineClicked()
    setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
end

if caffeine then
    caffeine:setClickCallback(caffeineClicked)
    setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
end

--
-- Browser Menu
--

-- Step 1: Take care, that Hammerspoon is the default browser
if hs.urlevent.getDefaultHandler("http") ~= "org.hammerspoon.hammerspoon" then
    hs.urlevent.setDefaultHandler("http")
end

-- Step 2: Setup the browser menu
local active_browser     = hs.settings.get("active_browser") or "com.apple.safari"
local browser_menu       = hs.menubar.new()
local available_browsers = {
    ["com.apple.safari"] = {
        name = "Safari",
        icon = os.getenv("HOME") .. "/.hammerspoon/browsermenu/safari.png"
    },
    ["org.mozilla.firefoxdeveloperedition"] = {
        name = "FirefoxDeveloperEdition",
        icon = os.getenv("HOME") .. "/.hammerspoon/browsermenu/firefox.png"
    },
    ["com.google.chrome"] = {
        name = "Google Chrome",
        icon = os.getenv("HOME") .. "/.hammerspoon/browsermenu/chrome.png"
    },
}

function init_browser_menu()
    local menu_items = {}

    for browser_id, browser_data in pairs(available_browsers) do
        local image = hs.image.imageFromPath(browser_data["icon"]):setSize({w=16, h=16})

        if browser_id == active_browser then
            browser_menu:setIcon(image)
        end

        table.insert(menu_items, {
            title   = browser_data["name"],
            image   = image,
            checked = browser_id == active_browser,
            fn      = function()
                active_browser = browser_id
                hs.settings.set("active_browser", browser_id)
                init_browser_menu()
            end
        })
    end

    browser_menu:setMenu(menu_items)
end

init_browser_menu()

-- Step 3: Register a handler for opening URLs
hs.urlevent.httpCallback = function(scheme, host, params, fullURL)
    hs.urlevent.openURLWithBundle(fullURL, active_browser)
end

--
-- Draw things on screen
-- http://www.hammerspoon.org/go/#drawing


local mouseCircle = nil
local mouseCircleTimer = nil

function mouseHighlight()
    -- Delete an existing highlight if it exists
    if mouseCircle then
        mouseCircle:delete()
        if mouseCircleTimer then
            mouseCircleTimer:stop()
        end
    end
    -- Get the current co-ordinates of the mouse pointer
    mousepoint = hs.mouse.getAbsolutePosition()
    -- Prepare a big red circle around the mouse pointer
    mouseCircle = hs.drawing.circle(hs.geometry.rect(mousepoint.x-40, mousepoint.y-40, 80, 80))
    mouseCircle:setStrokeColor({["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1})
    mouseCircle:setFill(false)
    mouseCircle:setStrokeWidth(5)
    mouseCircle:show()

    -- Set a timer to delete the circle after 3 seconds
    mouseCircleTimer = hs.timer.doAfter(3, function() mouseCircle:delete() end)
end
hs.hotkey.bind({"cmd","alt","shift"}, "D", mouseHighlight)

--
-- hello world
--

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
  hs.notify.new({title="Hammerspoon", informativeText="Hello World"}):send()
end)



--
-- https://github.com/nathancahill/anycomplete
--

local anycomplete = require "anycomplete/anycomplete"
anycomplete.registerDefaultBindings({"cmd", "ctrl"}, 'L')
