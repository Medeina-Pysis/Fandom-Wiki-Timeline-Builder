Fandom Wiki Timeline Builder
This project provides a two-part solution for creating and displaying dynamic, interactive timelines on a Fandom Wiki. It consists of a graphical web-based Timeline Builder and a few wiki pages that work with Wikitext to render the timeline on any wiki page.

1. The Timeline Builder (HTML)
The provided timeline-builder.html file is a self-contained web application that serves as the visual interface for creating your timeline. You can simply open this file in a modern web browser to use it.

Key Features:

      1. User-Friendly Interface: The builder allows you to easily input the timeline's title, start and end dates, and tick increments.
      
      2. Live Preview: As you add and edit events, a live, visual representation of your timeline is rendered directly on the page, allowing you to fine-tune its appearance.
      
      3. Wikitext Generation: The application automatically generates the Wikitext you need. This code includes all your timeline data encoded in a simple, easy-to-use format.
      
      4. Load from Wikitext: You can copy the Wikitext from an existing timeline on your wiki and paste it into the builder. The app will parse the data and populate the form fields, allowing you to easily edit and update a previously created timeline.

Along with these are a number of smaller features that are mirrored by the lua code in the module, features that simply make the timeline work correctly, such as collision detection, alternating sides, auto-adjusting box-width, etc.

2. Wiki pages
   1. Template:Timeline - collects the wikitext you paste and passes it on to Module:Timeline. Stored in template.html
   2. Template:Timeline/doc - contains all the documentation for how to create a timeline using this software. Stored in doc.html
   3. Module:Timeline - this page contains the lua code that generates the timeline you will see on your article. Stored in Module.lua

Once you create these the pages in your wiki, follow the instructions in Template:Timeline/doc in order to create your first timeline!

