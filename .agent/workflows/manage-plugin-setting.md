---
description: How to add or edit a setting on the plugin setting page for Canvas SEB
---

This workflow guides you through adding or editing a configuration setting for the `canvas_seb` plugin.

## Prerequisites
- Identify the setting name (e.g., `enable_feature_x`).
- Decide on the setting type (boolean, string, etc.).

## Steps

### 1. Register the setting in the Engine
Open `lib/canvas_seb/engine.rb` and add your new setting to the `settings` hash within the `Canvas::Plugin.register` block.

```ruby
# lib/canvas_seb/engine.rb

Canvas::Plugin.register :canvas_seb, nil, {
  # ... other properties
  settings: {
    enabled: true,
    worker: "CanvasSeb::Worker",
    disable_quiz_start: false,
    # Add your new setting here
    your_new_setting: "default_value"
  }
}
```

### 2. Update the Settings UI
Open `app/views/plugins/_canvas_seb_settings.html.erb` and add a new row to the settings table for your field.

#### For a Checkbox (Boolean):
```erb
<tr>
  <td style="vertical-align: top;"><%= blabel :canvas_seb, :your_new_setting, :en => "Label for Setting" %></td>
  <td>
    <%= f.check_box :your_new_setting, :checked => Canvas::Plugin.value_to_boolean(settings[:your_new_setting]) %>
    <small><%= t(:your_new_setting_hint, "Description of what this setting does.") %></small>
  </td>
</tr>
```

#### For a Text Field (String):
```erb
<tr>
  <td><%= blabel :canvas_seb, :your_new_setting, :en => "Label for Setting" %></td>
  <td>
    <%= f.text_field :your_new_setting, :value => settings[:your_new_setting] %>
  </td>
</tr>
```

### 3. Use the Setting in Logic
You can access the setting anywhere in your code using `Canvas::Plugin.find(:canvas_seb).settings`.

```ruby
settings = Canvas::Plugin.find(:canvas_seb).settings || {}
if settings[:your_new_setting] == "some_value"
  # Do something
end
```

### 4. Modifying an Existing Setting
If you are editing an existing setting, you must ensure that all references to the setting key are updated throughout the codebase.

#### Find Usages
Run the following command to find all occurrences of the setting key:
```bash
grep -r "your_setting_key" .
```
Or if using ripgrep:
```bash
rg "your_setting_key"
```

#### Update References
- Check logic in `lib/` (extensions, engines).
- Check views where the setting might be displayed or used.
- Ensure the default value in `lib/canvas_seb/engine.rb` is still appropriate if you changed the type.

### 5. Verify Changes
1. Go to **Site Admin** > **Plugins**.
2. Find **Canvas SEB** and click its name or settings icon.
3. Verify the new field appears and saves correctly.

## Common Operations
- **Adding a default value**: Ensure step 1 is completed so the plugin has a fallback if the setting is never saved.
- **Handling Booleans**: Always use `Canvas::Plugin.value_to_boolean(settings[:key])` when reading checkboxes from the settings hash, as Canvas may store them as strings ("1" or "0").
