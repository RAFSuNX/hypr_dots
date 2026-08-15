-- Default Material You dark theme — overwritten by theme-switch.sh on first login

hl.config({
    general = {
        ["col.active_border"]   = { colors = { "rgb(938F99)", "rgb(49454F)" }, angle = 45 },
        ["col.inactive_border"] = "rgb(49454F)",
    },
    group = {
        ["col.border_active"]          = "rgb(938F99)",
        ["col.border_inactive"]        = "rgb(49454F)",
        ["col.border_locked_active"]   = "rgb(F2B8B5)",
        ["col.border_locked_inactive"] = "rgb(938F99)",
        groupbar = {
            ["col.active"]          = "rgb(4F378B)",
            ["col.inactive"]        = "rgb(211F26)",
            ["col.locked_active"]   = "rgb(F2B8B5)",
            ["col.locked_inactive"] = "rgb(49454F)",
        },
    },
    misc = {
        background_color = "rgb(141218)",
    },
    decoration = {
        shadow = {
            color = "rgba(141218ee)",
        },
    },
})
