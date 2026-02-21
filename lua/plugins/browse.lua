return {
    "lalitmee/browse.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    
opts = {
    -- The default search provider for `input_search()`.
    -- Values: "google", "duckduckgo", "bing", "brave".
    provider = "google",

    -- A Lua table containing your bookmarks.
    bookmarks = {},

    -- A list of absolute paths to external bookmark files.
    bookmark_files = {},

    -- Configuration for importing bookmarks from web browsers.
    browser_bookmarks = {
        enabled = false,
        browsers = {
            chrome = false,
            firefox = false,
            safari = false,
            edge = false,
        },
        group_by_folder = true,
        auto_detect = true,
    },

    -- If `true`, duplicate bookmark URLs from all sources will be removed.
    deduplicate_bookmarks = true,

    -- If `true`, bookmarks loaded from files and browsers will be cached to improve performance.
    cache_bookmarks = true,

    -- The duration in seconds for which the bookmark cache is valid.
    cache_duration = 60,

    -- If `true`, the plugin will create default user commands for you.
    create_commands = true,

    -- A table to configure the Telescope theme for each picker.
    themes = {
        browse = "dropdown",
        manual_bookmarks = "dropdown",
        browser_bookmarks = nil, -- nil uses the default Telescope theme
    },

    -- Configuration for parsing plain text (`.txt`) bookmark files.
    plain_text = {
        delimiters = { ":", "=" },
        comment_chars = { "#", ";" },
    },

    -- Customize the icons used in the Telescope pickers.
    icons = {
        bookmark_alias = "->",
        bookmarks_prompt = "",
        grouped_bookmarks = "->",
        file_bookmark = "📄",
        browser_bookmark = "🌐",
    },

    -- If `true`, the search query is preserved when you navigate into a nested bookmark group.
    persist_grouped_bookmarks_query = false,

    -- Configuration for the bookmark picker.
    bookmark_picker = {
        -- If `true`, nested bookmarks are displayed in a nested structure.
        -- If `false`, all bookmarks are shown in a flat list.
        show_nested = true,
    },

    -- The number of Telescope pickers to cache, enabling back-navigation.
    cache_pickers = 10,

    -- If `true`, bookmark results are sorted alphabetically.
    -- If `false`, they are displayed in the order they were defined.
    sort_results = true,
},
}
