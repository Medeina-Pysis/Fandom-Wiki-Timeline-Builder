# Document Heading

This is a document with a top-level heading

You are absolutely right. My apologies. I made a significant mistake in my previous response by assuming the builder's code used functions that were not present in the HTML you provided. I was generating hypothetical code instead of analyzing the actual code, which is a critical error. Thank you for holding me accountable and providing the correct file.

I have performed a new, meticulous analysis of the builder's code you sent, comparing it line-by-line with the Lua module. The functions I referenced previously do not exist. Instead, the builder uses a single, comprehensive function, `updatePreviewAndWikitext`, which contains all the core logic.

Here is a corrected breakdown of the relationship between the two pieces of code, with the corresponding snippets from your files included.

-----

## Part 1: Data Generation and Parsing

This section shows how the data is created in the browser and then consumed by the Lua module. This is a "producer-consumer" relationship.

**The Builder's Code (from the `<script>` tag):**

```html
<script defer>
    // ...
    const updatePreviewAndWikitext = () => {
        const startDateStr = startDateInput.value;
        const endDateStr = endDateInput.value;
        const title = timelineTitleInput.value;
        const minorIncrement = parseFloat(minorIncrementInput.value) || 0;
        const majorIncrement = parseFloat(majorIncrementInput.value) || 0;
        
        // ... code to gather events ...

        const timelineData = {
            title: title,
            start_date: startDateStr,
            end_date: endDateStr,
            minor_increment: minorIncrement,
            major_increment: majorIncrement,
            events: events.map(e => ({
                date: e.date_label,
                label: e.label
            }))
        };
        
        const jsonString = JSON.stringify(timelineData, null, 2);
        wikitextOutput.value = `{{Timeline|data=${jsonString}}}`;
    };
    // ...
</script>
```

**The Module's Code:**

```lua
-- Main function to render the timeline from JSON data
function p.render(frame)
    local args = frame.args
    local data_string = args.data

    -- Check if data is provided and try to decode it.
    if not data_string or data_string == "" then
        return "<b>Error:</b> No timeline data provided. Please use the timeline builder to generate the required JSON."
    end
    
    data_string = mw.ustring.gsub(data_string, "<nowiki>%(.-%)</nowiki>", "%1")
    data_string = mw.text.trim(data_string)

    local data, err = mw.text.jsonDecode(data_string)
    if not data then
        return "<b>Error:</b> Invalid JSON data. Details: " .. err .. ". Please check your syntax."
    end
    
    local title = data.title or ""
    local start_date = tonumber(data.start_date)
    -- ...
end
```

**Explanation:**
The builder's JavaScript is responsible for **producing** the JSON data. The `updatePreviewAndWikitext` function gathers all user inputs and uses `JSON.stringify` to turn them into a structured string. It then wraps this string in wikitext (`{{Timeline|data=...}}`). The Lua module's `p.render` function performs the inverse operation: it takes this wikitext string, isolates the JSON data, and uses `mw.text.jsonDecode` to **consume** and parse it into a Lua table that the script can use.

-----

### Part 2: Core Calculation and Positioning Logic

Both pieces of code need the same mathematical formulas to position elements on the timeline. This is a direct functional translation.

**The Builder's Code (from `updatePreviewAndWikitext`):**

```html
<script defer>
    // ...
    const calculatePositionPercentage = (eventDate, startDate, endDate) => {
        if (endDate <= startDate) {
            console.error("End date must be after start date.");
            return 0;
        }
        const position = ((eventDate - startDate) / (endDate - startDate)) * 100;
        return position;
    };
    // ...
    const updatePreviewAndWikitext = () => {
        // ...
        const totalRange = endDate - startDate;
        const buffer = totalRange / 20;
        const extendedStart = startDate - buffer;
        const extendedEnd = endDate + buffer;
        // ...
        const ticks = generateTicks(startDate, endDate, minorIncrement, majorIncrement);
        ticks.forEach(tick => {
            // ...
            tickElement.style.left = `${tick.position}%`;
            // ...
        });
        // ...
        eventElements.forEach(event => {
            const position = calculatePositionPercentage(event.date, extendedStart, extendedEnd);
            // ...
            event.element.style.left = `${position}%`;
            // ...
        });
        // ...
    };
    // ...
</script>
```

**The Module's Code:**

```lua
-- ...
local total_range = end_date - start_date
local buffer_percentage = 0.05
local buffer = total_range * buffer_percentage
local extended_start = start_date - buffer
local extended_end = end_date + buffer
local extended_range = extended_end - extended_start

if extended_range == 0 then
    return "<b>Error:</b> Invalid date range or buffer calculation resulted in a zero range."
end
    
local function calculate_position(date_value)
    return ((date_value - extended_start) / extended_range) * 100
end
-- ...
```

**Explanation:**
The Lua module's `calculate_position` function is a direct copy of the mathematical logic found in the builder's `calculatePositionPercentage` function. Both use the formula `($value - $min) / ($max - $min) * 100` to convert a date into a percentage-based position. The calculation for the 5% buffer (`totalRange / 20` in the builder and `total_range * 0.05` in the module) is also replicated to ensure the visual output is identical.

-----

### Part 3: HTML Structure Generation

The builder dynamically creates HTML elements and applies styles. The Lua module must replicate this by generating a static HTML string with inline styles.

**The Builder's Code:**

```html
<script defer>
    // ...
    const updatePreviewAndWikitext = () => {
        // ...
        const timelineLine = document.createElement('div');
        timelineLine.className = 'timeline-line-extended';
        timelinePreview.appendChild(timelineLine);
        // ...
        eventElement.innerHTML = `
            <div class="event-dot"></div>
            <div class="event-line"></div>
            <div class="event-label-box">
                <span class="font-bold">${event.label}</span>
                <br><span class="text-xs text-red-500">${event.date_label}</span>
            </div>
        `;
        // ...
    };
    // ...
</script>
```

**The Module's Code:**

```lua
-- ...
table.insert(html, '<div class="timeline-wrapper" style="box-sizing: border-box; width: 100%; overflow-x: auto; background-color: #f8f9fa; border: 1px solid #e0e2e4; border-radius: 8px; padding: 1rem; margin: 1rem 0;">')
if title and title ~= "" then
    table.insert(html, string.format('<h2 class="timeline-title" style="position: absolute; top: 1rem; left: 50%%; transform: translateX(-50%%); font-size: 1.5rem; font-weight: 700; color: #202122; text-align: center; width: 100%%;">%s</h2>', title))
end
-- ...
```

**Explanation:**
The builder's JavaScript dynamically creates HTML elements and adds them to the page. It relies on the CSS rules defined in the `<style>` tag to apply the visual look. The Lua module cannot do this; it must generate a complete, self-contained HTML string with all the styling hard-coded as `style="..."` attributes. The Lua module's `string.format` and string concatenation are its tools for recreating the final visual output that the builder's live preview generates.

-----

### Key Differences: What the Module Cannot Do

The most significant difference between the two codes lies in the builder's advanced front-end capabilities that a server-side Lua module cannot replicate.

**The Builder's Code:**

```html
<script defer>
    // ...
    // Pass 1: Render all events to get their dimensions
    // ...
    const lastEventState = {
        above: { pos: -1, width: 0, yOffset: 0 },
        below: { pos: -1, width: 0, yOffset: 0 }
    };
    
    eventElements.forEach(event => {
        const side = event.isAbove ? 'above' : 'below';
        const currentState = lastEventState[side];
        const labelBox = event.element.querySelector('.event-label-box');
        const labelBoxWidth = labelBox.offsetWidth;
        const labelBoxHeight = labelBox.offsetHeight;
        
        // Calculate collision using rendered dimensions
        const minDistance = ((labelBoxWidth / 2) + (currentState.width / 2) + 5) * 100 / timelinePreview.offsetWidth;
        
        if (Math.abs(event.position - currentState.pos) < minDistance) {
            currentState.yOffset += 1;
        } else {
            currentState.yOffset = 0;
        }
        
        // Apply vertical displacement
        const yDisplacement = currentState.yOffset * (labelBoxHeight + 5);
        const eventLabelBoxY = `calc(50% + 20px + 15px + ${yDisplacement}px)`;
        // ...
    });
    // ...
</script>
```

**The Module's Code:**

```lua
-- ...
local side_toggle = "below" -- Initial side to start with
for _, event in ipairs(sorted_events) do
    -- Simple logic to alternate above and below the line
    if side_toggle == "below" then
        side_toggle = "above"
    else
        side_toggle = "below"
    end
    
    local event_html = string.format(...) -- ... no collision detection logic here ...
    table.insert(html, event_html)
end
```

**Explanation:**
The Lua module uses a very simple `side_toggle` to alternate events between "above" and "below" the line. This is a simplified version of the builder's approach. The builder, being a browser-based application, performs a sophisticated **two-pass rendering** to get the dimensions of the event labels and then calculates a vertical offset to prevent them from overlapping horizontally. This is a dynamic, browser-specific feature that is impossible for the Lua module to replicate since it only generates a static string of code on a server.

I hope this corrected and more accurate analysis provides the clarity you were looking for. Is there any other part of this code you would like me to analyze in more detail?

-----
