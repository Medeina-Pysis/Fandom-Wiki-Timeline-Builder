--[[
This module takes JSON data from a wiki timeline builder and renders the
corresponding HTML. It now relies on a separate CSS file (MediaWiki:Common.css) for styling,
removing all inline style attributes.
]]--
local p = {}

-- Main function to render the timeline from JSON data
function p.render(frame)
    
    -- Part 1: Data Extraction and Validation
    -- This section extracts and validates the input data from the template arguments.

        -- Get the arguments passed to the template.
        local args = frame.args
        local data_string = args.data

        -- Check if data is provided and try to decode it.
        if not data_string or data_string == "" then
            return "<b>Error:</b> No timeline data provided. Please use the timeline builder to generate the required JSON."
        end

        -- Strip <nowiki> tags and any extra whitespace from the data string before decoding.
        data_string = mw.ustring.gsub(data_string, "<nowiki>%(.-%)</nowiki>", "%1")
        data_string = mw.text.trim(data_string)

        local data, err = mw.text.jsonDecode(data_string)
        if not data then
            return "<b>Error:</b> Invalid JSON data. Details: " .. err .. ". Please check your syntax."
        end

        -- Extract timeline parameters and events.
        local title = data.title or ""
        local start_date = tonumber(data.start_date)
        local end_date = tonumber(data.end_date)
        local minor_increment = tonumber(data.minor_increment)
        local major_increment = tonumber(data.major_increment)
        local events = data.events or {}

        if not start_date or not end_date then
            return "<b>Error:</b> Start date and end date are required."
        end

        if start_date >= end_date then
            return "<b>Error:</b> Start date must be less than the end date."
        end

    -- Part 2: Range Calculation and Buffering
    -- This section calculates the extended range for the timeline to ensure proper spacing.

        -- Calculate the extended range with a 5% buffer on each side.
        local total_range = end_date - start_date
        local buffer_percentage = 0.05
        local buffer = total_range * buffer_percentage
        local extended_start = start_date - buffer
        local extended_end = end_date + buffer
        local extended_range = extended_end - extended_start
        if extended_range == 0 then
            return "<b>Error:</b> Invalid date range or buffer calculation resulted in a zero range."
        end

        local html = {}

        -- Function to calculate the position of a date on the extended timeline.
        local function calculate_position(date_value)
            return ((date_value - extended_start) / extended_range) * 100
        end

    -- Part 3: HTML Structure and Dynamic Styling
    -- This section builds the HTML structure of the timeline with inline styles.

        -- Add the main wrapper.
        table.insert(html, '<div class="timeline-wrapper">')

        -- Timeline Title
        if title and title ~= "" then
            table.insert(html, string.format('<h2 class="timeline-title">%s</h2>', title))
        end

        -- Container for the timeline itself.
        table.insert(html, '<div class="timeline-container">')

        -- The main line, extended to account for padding.
        table.insert(html, '<div class="timeline-line-extended"></div>')

        -- Minor Ticks and Labels
        local tick_positions = {}
        
        local minor_step = minor_increment
        local major_step = major_increment
        
        -- Generate all ticks based on the full extended range.
        for i = start_date, end_date, minor_step do
            local position = calculate_position(i)
            table.insert(tick_positions, {
                pos = position,
                type = (major_step and (i % major_step == 0)) and "major" or "minor",
                label = tostring(i),
            })
        end

        -- Add start and end labels to the extended timeline.
        table.insert(tick_positions, { pos = calculate_position(start_date), type = "major", label = tostring(start_date) })
        table.insert(tick_positions, { pos = calculate_position(end_date), type = "major", label = tostring(end_date) })
    
    -- Part 4: Tick and Event Rendering Logic
    -- This section renders the ticks and events on the timeline.

        -- Render ticks

            -- Sort ticks to ensure correct rendering.
            table.sort(tick_positions, function(a, b) return a.pos < b.pos end)
            
            for _, tick in ipairs(tick_positions) do
                local tick_class = (tick.type == "major") and "timeline-tick-major" or "timeline-tick-minor"
                local tick_html = string.format('<div class="%s" style="left: %f%%;">', tick_class, tick.pos)
                
                -- Add labels for major ticks only
                if tick.type == "major" then
                    tick_html = tick_html .. string.format('<span class="timeline-tick-label">%s</span>', tick.label)
                end
                
                tick_html = tick_html .. '</div>'
                table.insert(html, tick_html)
            end

        -- Render events

            -- Sort events by date to ensure correct rendering order.
            local sorted_events = {}

            for _, event in ipairs(events) do
                table.insert(sorted_events, event)
            end

            table.sort(sorted_events, function(a, b) return a.date < b.date end)

            local side_toggle = "below" -- Initial side to start with

            -- Loop through events and render them
            for _, event in ipairs(sorted_events) do
                local position = calculate_position(tonumber(event.date))
                
                -- Simple logic to alternate above and below the line
                if side_toggle == "below" then
                    side_toggle = "above"
                else
                    side_toggle = "below"
                end
                
                -- Event wrapper
                table.insert(html, string.format('<div class="timeline-event-wrapper %s" style="left: %f%%;">', side_toggle, position))
                table.insert(html, '<div class="event-dot"></div>')
                table.insert(html, '<div class="event-line"></div>')
                table.insert(html, '<div class="event-label-box">')
                table.insert(html, string.format('<span style="font-weight: 700;">%s</span>', tostring(event.label)))
                table.insert(html, string.format('<br><span style="font-size: 0.75rem; color: #ef4444;">%s</span>', tostring(event.date_label)))
                table.insert(html, '</div>')
                table.insert(html, '</div>')

            end

    -- Part 5: Final Assembly and Output

        -- Concatenate all parts and return the final HTML.
        table.insert(html, "</div>")
        table.insert(html, "</div>")
        return table.concat(html)
end

return p
