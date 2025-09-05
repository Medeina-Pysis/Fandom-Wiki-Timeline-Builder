document.addEventListener('DOMContentLoaded', () => {
    const eventsList = document.getElementById('events-list');
    const addEventBtn = document.getElementById('add-event-btn');
    const timelineTitleInput = document.getElementById('timeline-title');
    const startDateInput = document.getElementById('start-date');
    const endDateInput = document.getElementById('end-date');
    const minorIncrementInput = document.getElementById('minor-increment');
    const majorIncrementInput = document.getElementById('major-increment');
    const timelinePreview = document.getElementById('timeline-preview');
    const wikitextOutput = document.getElementById('wikitext-output');
    const copyBtn = document.getElementById('copy-btn');
    
    let eventCounter = 0;

    const parseValue = (value) => {
        const trimmedValue = value.trim();
        const num = parseFloat(trimmedValue);
        if (!isNaN(num)) {
            return num;
        }
        const date = new Date(trimmedValue);
        return isNaN(date.getTime()) ? null : date.getTime();
    };

    const generateTicks = (start, end, minor, major) => {
        const ticks = [];
        const positions = new Set();
        const addTick = (pos, label, type) => {
            const roundedPos = Math.round(pos * 1000) / 1000;
            if (!positions.has(roundedPos)) {
                ticks.push({ position: pos, label: label, type: type });
                positions.add(roundedPos);
            }
        };

        const totalRange = end - start;
        const buffer = totalRange / 20; // 5% buffer on each side
        const extendedStart = start - buffer;
        const extendedEnd = end + buffer;

        // Always add start and end ticks with labels
        addTick(((start - extendedStart) / (extendedEnd - extendedStart)) * 100, startDateInput.value, 'major');
        addTick(((end - extendedStart) / (extendedEnd - extendedStart)) * 100, endDateInput.value, 'major');

        // Add minor and major ticks in a single loop
        if (minor > 0 || major > 0) {
            const step = minor > 0 ? minor : major;
            const startTick = Math.ceil(extendedStart / step) * step;
            
            for (let currentTick = startTick; currentTick <= extendedEnd; currentTick += step) {
                const position = ((currentTick - extendedStart) / (extendedEnd - extendedStart)) * 100;
                if (position > 0 && position < 100) {
                    let label = null;
                    let type = 'minor';
                    
                    // Check if the current tick is a major tick
                    if (major > 0 && Math.abs((currentTick - start) % major) < 1e-6) {
                        type = 'major';
                        label = currentTick.toString();
                    } else if (minor > 0) {
                        type = 'minor';
                    }
                    
                    addTick(position, label, type);
                }
            }
        }

        // Filter out non-unique positions before sorting
        const finalTicks = Array.from(new Map(ticks.map(tick => [Math.round(tick.position * 1000) / 1000, tick])).values());
        finalTicks.sort((a, b) => a.position - b.position);

        return finalTicks;
    };


    const updatePreviewAndWikitext = () => {
        const startDateStr = startDateInput.value;
        const endDateStr = endDateInput.value;
        const startDate = parseValue(startDateStr);
        const endDate = parseValue(endDateStr);
        const title = timelineTitleInput.value;
        const minorIncrement = parseFloat(minorIncrementInput.value) || 0;
        const majorIncrement = parseFloat(majorIncrementInput.value) || 0;

        timelinePreview.innerHTML = '';
        
        if (startDate === null || endDate === null) {
            wikitextOutput.value = 'Please enter valid numeric or date values for the start and end of the timeline.';
            return;
        }
        if (startDate >= endDate) {
            wikitextOutput.value = 'Start date must be less than the end date.';
            return;
        }

        const totalRange = endDate - startDate;
        const buffer = totalRange / 20; // 5% buffer on each side
        const extendedStart = startDate - buffer;
        const extendedEnd = endDate + buffer;
        
        // Add the main extended timeline line
        const timelineLine = document.createElement('div');
        timelineLine.className = 'timeline-line-extended';
        timelinePreview.appendChild(timelineLine);

        // Generate and render ticks
        const ticks = generateTicks(startDate, endDate, minorIncrement, majorIncrement);
        ticks.forEach(tick => {
            const tickElement = document.createElement('div');
            tickElement.className = `timeline-tick-${tick.type}`;
            tickElement.style.left = `${tick.position}%`;
            if (tick.label) {
                const labelElement = document.createElement('div');
                labelElement.className = 'timeline-tick-label';
                labelElement.textContent = tick.label;
                tickElement.appendChild(labelElement);
            }
            timelinePreview.appendChild(tickElement);
        });

        // Generate and render events
        const events = [];
        const eventElements = document.querySelectorAll('.event-item');
        eventElements.forEach((el, index) => {
            const dateInput = el.querySelector('.event-date');
            const labelInput = el.querySelector('.event-label');
            const date = parseValue(dateInput.value);
            if (date !== null && labelInput.value) {
                const position = ((date - extendedStart) / (extendedEnd - extendedStart)) * 100;
                if (position >= 0 && position <= 100) {
                    const isAbove = index % 2 === 0; // Alternate events above/below
                    const eventElement = document.createElement('div');
                    eventElement.className = `timeline-event-wrapper ${isAbove ? 'event-above' : 'event-below'}`;
                    eventElement.style.left = `${position}%`;
                    
                    eventElement.innerHTML = `
                        <div class="event-dot"></div>
                        <div class="event-line"></div>
                        <div class="event-label-box">
                            <span class="font-bold">${labelInput.value}</span>
                            <br><span class="text-xs text-gray-500">${dateInput.value}</span>
                        </div>
                    `;
                    timelinePreview.appendChild(eventElement);

                    events.push({
                        date: date,
                        date_label: dateInput.value,
                        label: labelInput.value,
                    });
                }
            }
        });

        // Sort events for consistent wikitext output
        events.sort((a, b) => a.date - b.date);

        const dataObject = {
            title: title,
            start_date: startDate,
            end_date: endDate,
            minor_increment: minorIncrement,
            major_increment: majorIncrement,
            events: events
        };

        const wikitextJson = JSON.stringify(dataObject, null, 2).replace(/"/g, "'");
        const wikitext = `{{Timeline|data=${wikitextJson}}}`;
        wikitextOutput.value = wikitext;
    };

    const addEventField = () => {
        // Ensure the events list element exists before adding
        if (!eventsList) {
            console.error("Events list element not found!");
            return;
        }

        const newId = `event-${eventCounter++}`;
        const eventDiv = document.createElement('div');
        eventDiv.className = 'event-item space-y-2 p-4 border rounded-md shadow-sm bg-gray-50';
        eventDiv.innerHTML = `
            <div class="flex items-center justify-between">
                <label class="block text-sm font-medium text-gray-700">Event</label>
                <button type="button" class="remove-event-btn text-red-500 hover:text-red-700 focus:outline-none">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm6 0a1 1 0 112 0v6a1 1 0 11-2 0V8z" clip-rule="evenodd" />
                    </svg>
                </button>
            </div>
            <input type="text" placeholder="Date (e.g., -100, 50, or YYYY-MM-DD)" class="event-date mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500">
            <input type="text" placeholder="Event Label" class="event-label mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500">
        `;
        eventsList.appendChild(eventDiv);

        // Attach listeners to the newly created elements
        eventDiv.querySelector('.remove-event-btn').addEventListener('click', () => {
            eventsList.removeChild(eventDiv);
            updatePreviewAndWikitext();
        });
        eventDiv.querySelectorAll('input').forEach(input => {
            input.addEventListener('input', updatePreviewAndWikitext);
        });
        updatePreviewAndWikitext();
    };

    addEventBtn.addEventListener('click', addEventField);
    startDateInput.addEventListener('input', updatePreviewAndWikitext);
    endDateInput.addEventListener('input', updatePreviewAndWikitext);
    timelineTitleInput.addEventListener('input', updatePreviewAndWikitext);
    minorIncrementInput.addEventListener('input', updatePreviewAndWikitext);
    majorIncrementInput.addEventListener('input', updatePreviewAndWikitext);
    
    copyBtn.addEventListener('click', () => {
        wikitextOutput.select();
        document.execCommand('copy');
        const originalText = copyBtn.textContent;
        copyBtn.textContent = 'Copied!';
        setTimeout(() => {
            copyBtn.textContent = originalText;
        }, 2000);
    });

    // Add the initial event field on page load
    addEventField();
});
