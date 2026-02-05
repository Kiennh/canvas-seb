# SEB Media Player Customization

This module provides Safe Exam Browser (SEB) specific customizations for the Canvas Media Player.

## Features

This module provides two configurable modes for media player controls when accessed through Safe Exam Browser:

### Mode 1: Disable Media Seek Controls (Default)
When enabled via plugin settings (`disable_media_seek`):
- Hides the timeline/timebar control (prevents seeking/skipping)
- Hides the volume control
- Hides the captions toggle
- Hides the player settings menu
- Hides the fullscreen button
- **Keeps only the play/pause button visible**

### Mode 2: Hide All Media Controls
When enabled via plugin settings (`hide_all_media_controls`):
- Completely hides the entire control bar
- Video plays but user has no controls at all
- This mode takes priority over "Disable Media Seek Controls"

### Benefits
This provides a simplified, exam-focused media viewing experience that prevents students from:
- Skipping ahead in instructional videos
- Adjusting playback settings
- Entering fullscreen mode (which could hide proctoring overlays)
- Having any control over playback (in hide-all mode)

## How It Works

### Detection
The module detects SEB context by checking for:
- `X-SafeExamBrowser-ConfigKeyHash` header
- `X-SafeExamBrowser-RequestHash` header

### Implementation
1. **MediaObjectsControllerExtension** (`lib/canvas_seb/media_objects_controller_extension.rb`)
   - Hooks into the `iframe_media_player` action
   - Detects SEB headers
   - Injects SEB-specific CSS and JS bundles when SEB is detected

2. **CSS Customization** (`ui/shared/canvas-media-player-seb/seb-media-player.css`)
   - Defines styles to hide specific media player controls
   - Uses `!important` to override default styles

4. **JavaScript Hooking** (`ui/shared/canvas-media-player-seb/index.js`)
   - Monkey-patches `React.createElement` to intercept `MediaPlayer` rendering
   - Injects `hideControls: true` prop when `hide_all_media_controls` is enabled
   - This approach avoids modifying core Canvas LMS source code.
   - Also adds `seb-media-player` class to media player containers for CSS targeting.

## Files

```
gems/plugins/canvas_seb/
├── app/jsx/bundles/
│   └── media_player.js                        # JS Bundle Entry Point
├── lib/canvas_seb/
│   ├── media_objects_controller_extension.rb  # Controller hook
│   └── engine.rb                               # Updated to register extension
└── ui/shared/canvas-media-player-seb/
    ├── index.js                                # JS Implementation & Hook
    ├── seb-media-player.css                    # SEB-specific styles
    ├── package.json                            # Package metadata
    └── README.md                               # This file
```

## Testing

To test this functionality:

1. Enable the Canvas SEB plugin
2. Configure a course with a SEB key
3. Access a page with embedded media through Safe Exam Browser
4. Verify that only the play/pause button is visible

## Future Enhancements

- [ ] Add configuration option to allow/disallow specific controls
- [ ] Add visual indicator that SEB mode is active
- [ ] Support for audio-only players with different control sets
