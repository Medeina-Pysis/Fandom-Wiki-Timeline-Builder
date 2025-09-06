-- Module:Timeline
-- This Lua module takes JSON data from a wiki timeline builder and renders the
-- corresponding HTML. It handles calculating positions for ticks and events
-- and dynamically generates the complete timeline structure with inline styles.
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
    local boxHeight = tonumber(data.boxHeight) or 3.5 -- Default box height in 'rem'
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

    -- Part 3: HTML Structure and Dynamic Styling
    -- This section builds the HTML structure of the timeline with inline styles.
    
    -- Function to calculate the position of a date on the extended timeline.
    local function calculate_position(date_value)
        return ((date_value - extended_start) / extended_range) * 100
    end

    -- Initialize HTML parts.
    local html = {}

    -- Add the main wrapper.
    table.insert(html, '<div class="timeline-wrapper" style="box-sizing: border-box; width: 100%; overflow-x: auto; background-color: #f8f9fa; border: 1px solid #e0e2e4; border-radius: 8px; padding: 1rem; margin: 1rem 0;">')

    -- Timeline Title

    -- Uncomment the following lines to include a title at the top of the timeline.
    
    -- if title and title ~= "" then
    --     table.insert(html, string.format('<h2 class="timeline-title" style="position: absolute; top: 1rem; left: 50%%; transform: translateX(-50%%); font-size: 1.5rem; font-weight: 700; color: #202122; text-align: center; width: 100%%;">%s</h2>', title))
    -- end

    -- Container for the timeline itself.
    table.insert(html, '<div class="timeline-container" style="position: relative; padding: 4rem 1rem 3rem; min-height: 350px; width: 960px; overflow-x: hidden; display: flex; flex-direction: column; justify-content: center;">')

    -- The main line, extended to account for padding.
    table.insert(html, '<div class="timeline-line-extended" style="position: absolute; top: 50%; left: 0; width: 100%; height: 4px; background-color: #9ca3af; transform: translateY(-50%); z-index: 10; border-radius: 2px;"></div>')

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
        local tick_style = string.format("position: absolute; top: 50%%; background-color: %s; z-index: 20; transform: translateY(-50%%) translateX(-50%%); left: %f%%;",
            (tick.type == "major") and "#4b5563" or "#d1d5db",
            tick.pos)

        local tick_size = (tick.type == "major") and 'height: 15px; width: 4px; border-radius: 2px;' or 'height: 10px; width: 2px;'
        
        table.insert(html, string.format('<div style="%s %s"></div>', tick_style, tick_size))
        
        -- Add labels for major ticks only
        if tick.type == "major" then
            -- Position labels relative to the timeline line
            local label_style = string.format("position: absolute; top: calc(50%% + 0.6rem); left: %f%%; transform: translateX(-50%%); white-space: nowrap; font-size: 0.75rem; color: #4b5563; background-color: #f3f4f6; padding: 0 4px; z-index: 40;", tick.pos)
            table.insert(html, string.format('<div style="%s">%s</div>', label_style, tick.label))
        end
    end

    -- Render events

    -- Sort events by date to ensure correct rendering order.
    local sorted_events = {}

    for _, event in ipairs(events) do
        table.insert(sorted_events, event)
    end

    table.sort(sorted_events, function(a, b) return a.date < b.date end)


    -- The vertical gap between stacked boxes, in 'rem'.
    local vertical_gap_rem = 5;
    local line_base_height = 40 -- Base line height in pixels
    local container_width_px = 960 -- Assumed container width for 'rem' to 'px' conversion.
    local lastEventState = {
        -- The key `above` is mapped to a nested table.
        above = { 
            pos = -1, 
            width = 0, 
            yOffset = 0 
        },
        -- The key `below` is mapped to another nested table.
        below = { 
            pos = -1, 
            width = 0, 
            yOffset = 0 
        }
    }

    for index, event in ipairs(sorted_events) do
        local position = calculate_position(tonumber(event.date))
        local isAbove = index % 2 ~= 0 and 'above' or 'below'

        local currentState = lastEventState[isAbove]

        local labelBoxWidth = event.width
        local labelBoxHeight = boxHeight

        -- Calculate the minimum required distance between labels to avoid horizontal overlap in percentage
        local minDistance = ((labelBoxWidth / 2) + (currentState.width / 2) + 5) * 100 / container_width_px;
        
        -- Collision detection logic, based on your JS code
        if math.abs(position - currentState.pos) < minDistance then
            currentState.yOffset = currentState.yOffset + 1;
        else 
            currentState.yOffset = 0;
        end
        
        -- The y-displacement is calculated based on the current stacking level
        local yDisplacement = currentState.yOffset * (labelBoxHeight + vertical_gap_rem);

        currentState.pos = position;
        currentState.width = labelBoxWidth;

        local vertical_offset = 'calc' .. string.format('(50%% + 20px + 15px + %fpx)', yDisplacement)
        local line_height = 'calc' .. string.format('(50%% + %fpx + %fpx)',line_base_height, yDisplacement)
        
        local event_html = string.format(
            '<div class="event-wrapper" style="position: absolute; top: 50%%; left: %f%%; transform: translateY(-50%%); z-index: 30; text-align: center; display: flex; align-items: center; justify-content: center; %s;">' ..
                '<div class="event-dot" style="position: absolute; top: 50%%; left: 50%%; transform: translate(-50%%, -50%%); width: 16px; height: 16px; background-color: #ef4444; border-radius: 50%%; z-index: 50;"></div>' ..
                '<div class="event-line" style="position: absolute; left: 50%%; transform: translateX(-50%%); width: 2px; height: %s; background-color: #ef4444; z-index: 25; %s: 50%%;"></div>' ..
                '<div class="event-label-box" style="position: absolute; left: 50%%; transform: translateX(-50%%); background-color: #fff; padding: 0.5rem 0.75rem; border-radius: 0.5rem; box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1); white-space: nowrap; font-size: 0.875rem; z-index: 60; %s: %s;">' ..
                    '<span style="font-weight: 700; color: #4b5563;">%s</span>' ..
                    '<br><span style="font-size: 0.75rem; color: #ef4444;">%s</span>' ..
                '</div>' ..
            '</div>',
            position,
            (isAbove == 'above') and "flex-direction: column-reverse;" or "flex-direction: column;",
            line_height,
            (isAbove == 'above') and "bottom" or "top",
            (isAbove == 'above') and "bottom" or "top",
            vertical_offset,
            tostring(event.label),
            tostring(event.date) 
        )
        table.insert(html, event_html)
    end

    -- Part 5: Final Assembly and Output

    -- Concatenate all parts and return the final HTML.
    table.insert(html, "</div>")
    table.insert(html, "</div>")
    return table.concat(html)
end
return p
