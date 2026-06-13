local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

sbar.add("event", "omniwm_workspace_change")

local spaces = {}

local function parse_lines(s)
    local result = {}
    for line in s:gmatch("[^\r\n]+") do
        table.insert(result, line)
    end
    return result
end

local function get_workspaces()
    local file = io.popen("omniwmctl query workspaces --format tsv 2>/dev/null")
    if not file then return {} end

    local result = file:read("*a")
    file:close()

    local workspaces = {}

    for line in result:gmatch("[^\r\n]+") do
        if not line:match("^ID%s+") then
            local columns = {}

            for column in line:gmatch("[^\t]+") do
                table.insert(columns, column)
            end

            local workspace = columns[2]
            local current = columns[5]

            if workspace and workspace ~= "-" then
                table.insert(workspaces, {
                    id = workspace,
                    name = workspace,
                    current = current == "yes",
                })
            end
        end
    end

    return workspaces
end

local function update_spaces()
    local workspaces = get_workspaces()

    for _, workspace in ipairs(workspaces) do
        local space = spaces[workspace.id]

        if space then
            local selected = workspace.current

            space.item:set({
                icon = {
                    string = workspace.name,
                    highlight = selected,
                },
                label = { highlight = selected },
                background = {
                    border_color = selected and colors.black or colors.bg2,
                },
            })

            space.bracket:set({
                background = {
                    border_color = selected and colors.grey or colors.bg2,
                },
            })
        end
    end
end

for i = 1, 7, 1 do
    local workspace_id = tostring(i)

    local space = sbar.add("item", "space." .. i, {
        icon = {
            font = { family = settings.font.numbers },
            string = i,
            padding_left = 15,
            padding_right = 8,
            color = colors.white,
            highlight_color = colors.red,
        },
        label = {
            padding_right = 20,
            color = colors.grey,
            highlight_color = colors.white,
            font = "sketchybar-app-font:Regular:16.0",
            y_offset = -1,
            string = " —",
        },
        padding_right = 1,
        padding_left = 1,
        background = {
            color = colors.bg1,
            border_width = 1,
            height = 26,
            border_color = colors.black,
        },
        popup = {
            background = {
                border_width = 5,
                border_color = colors.black,
            },
        },
    })

    local space_bracket = sbar.add("bracket", { space.name }, {
        background = {
            color = colors.transparent,
            border_color = colors.bg2,
            height = 28,
            border_width = 2,
        },
    })

    -- Padding item
    sbar.add("item", "space.padding." .. i, {
        width = settings.group_paddings,
    })

    local space_popup = sbar.add("item", {
        position = "popup." .. space.name,
        padding_left = 5,
        padding_right = 0,
        background = {
            drawing = true,
            image = {
                corner_radius = 9,
                scale = 0.2,
            },
        },
    })

    spaces[workspace_id] = {
        item = space,
        bracket = space_bracket,
        popup = space_popup,
    }

    space:subscribe("omniwm_workspace_change", update_spaces)

    space:subscribe("mouse.clicked", function(env)
        if env.BUTTON == "other" then
            space_popup:set({
                background = {
                    image = "space." .. workspace_id,
                },
            })
            space:set({ popup = { drawing = "toggle" } })
        else
            sbar.exec("omniwmctl command switch-workspace " .. workspace_id)
        end
    end)

    space:subscribe("mouse.exited", function(_)
        space:set({ popup = { drawing = false } })
    end)
end

local workspace_window_observer = sbar.add("item", {
    drawing = false,
    updates = true,
})

local spaces_indicator = sbar.add("item", {
    padding_left = -3,
    padding_right = 0,
    icon = {
        padding_left = 8,
        padding_right = 9,
        color = colors.grey,
        string = icons.switch.on,
    },
    label = {
        width = 0,
        padding_left = 0,
        padding_right = 8,
        string = "Spaces",
        color = colors.bg1,
    },
    background = {
        color = colors.with_alpha(colors.grey, 0.0),
        border_color = colors.with_alpha(colors.bg1, 0.0),
    },
})

local function update_workspace_apps()
    local file = io.popen("omniwmctl query windows --format tsv 2>/dev/null")
    if not file then return end

    local result = file:read("*a")
    file:close()

    local workspace_apps = {}

    for line in result:gmatch("[^\r\n]+") do
        -- Skip header
        if not line:match("^ID%s+PID%s+APP%s+") then
            local columns = {}

            for column in line:gmatch("[^\t]+") do
                table.insert(columns, column)
            end

            local app = columns[3]
            local workspace = columns[5]

            if workspace and app and workspace ~= "-" and app ~= "-" then
                workspace_apps[workspace] = workspace_apps[workspace] or {}

                local lookup = app_icons[app]
                local icon = lookup or app_icons["Default"]

                workspace_apps[workspace][icon] = true
            end
        end
    end

    for workspace_id, space in pairs(spaces) do
        local icon_line = ""

        if workspace_apps[workspace_id] then
            for icon, _ in pairs(workspace_apps[workspace_id]) do
                icon_line = icon_line .. icon
            end
        end

        if icon_line == "" then
            icon_line = " —"
        end

        sbar.animate("tanh", 10, function()
            space.item:set({ label = icon_line })
        end)
    end
end

workspace_window_observer:subscribe("omniwm_workspace_change", function(_)
    update_workspace_apps()
end)

update_workspace_apps()

spaces_indicator:subscribe("swap_menus_and_spaces", function(_)
    local currently_on = spaces_indicator:query().icon.value == icons.switch.on
    spaces_indicator:set({
        icon = currently_on and icons.switch.off or icons.switch.on,
    })
end)

spaces_indicator:subscribe("mouse.entered", function(_)
    sbar.animate("tanh", 30, function()
        spaces_indicator:set({
            background = {
                color = { alpha = 1.0 },
                border_color = { alpha = 1.0 },
            },
            icon = { color = colors.bg1 },
            label = { width = "dynamic" },
        })
    end)
end)

spaces_indicator:subscribe("mouse.exited", function(_)
    sbar.animate("tanh", 30, function()
        spaces_indicator:set({
            background = {
                color = { alpha = 0.0 },
                border_color = { alpha = 0.0 },
            },
            icon = { color = colors.grey },
            label = { width = 0 },
        })
    end)
end)

spaces_indicator:subscribe("mouse.clicked", function(_)
    sbar.trigger("swap_menus_and_spaces")
end)

update_spaces()
