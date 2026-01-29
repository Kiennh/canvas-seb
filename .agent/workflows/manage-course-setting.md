---
description: How to add or edit a course-level setting for the canvas_seb plugin
---

This workflow guides you through adding or editing a configuration setting that is specific to a Canvas Course.

## Prerequisites
- Identify the setting name (e.g., `course_enable_feature_x`).
- Decide on the setting type (boolean, string, etc.).

## Steps

### 1. Update the Course Settings UI
Open `app/views/canvas_seb/course_sample/index.html.erb` and add a new input field to the form.

#### For a Text Field (String):
```erb
<div style="margin-bottom: 15px;">
  <label for="your_setting_name" style="display: block; margin-bottom: 5px;">
    <%= t(:your_setting_label, "Label for Setting:") %>
  </label>
  <input type="text" name="your_setting_name" id="your_setting_name" value="<%= @your_setting_variable %>" style="width: 300px;" />
</div>
```

#### For a Checkbox (Boolean):
```erb
<div style="margin-bottom: 15px;">
  <label>
    <input type="checkbox" name="your_setting_name" value="1" <%= @your_setting_variable ? 'checked' : '' %> />
    <%= t(:your_setting_label, "Label for Setting") %>
  </label>
</div>
```

### 2. Load the Setting in the Controller
Open `app/controllers/canvas_seb/course_sample_controller.rb` and update the `index` action to fetch the setting from the course's settings hash.

```ruby
# app/controllers/canvas_seb/course_sample_controller.rb

def index
  if authorized_action(@context, @current_user, :view_canvas_seb_sample_page)
    # ... existing variables
    @your_setting_variable = @context.settings[:your_setting_name]
  end
end
```

### 3. Save the Setting in the Controller
In the same controller, update the `save_settings` action to store the new value.

```ruby
# app/controllers/canvas_seb/course_sample_controller.rb

def save_settings
  if authorized_action(@context, @current_user, :manage_canvas_seb_course_settings)
    current_settings = (@context.settings || {}).deep_dup
    
    # Update with new value from params
    current_settings[:your_setting_name] = params[:your_setting_name]
    
    if @context.update_attribute(:settings, current_settings)
      flash[:notice] = t(:settings_saved, "Course settings saved successfully.")
    else
      flash[:error] = t(:settings_failed, "Failed to save course settings.")
    end
    redirect_to course_canvas_seb_sample_path(id: @context.id)
  end
end
```

### 4. Use the Setting in Logic
You can access the setting via the course object (often named `@context` in controllers or `self.context` in extensions).

```ruby
# Example usage in an extension
course_setting = self.context.settings[:your_setting_name]
if course_setting == "expected_value"
  # Do something
end
```

## Common Operations
- **Handling Booleans**: Canvas checkboxes in standard forms may send "1" for checked and nothing for unchecked. 
  In `save_settings`: `current_settings[:your_setting_name] = params[:your_setting_name] == "1"`
- **Default Values**: When reading the setting, you might want to provide a fallback:
  `@your_setting_variable = @context.settings[:your_setting_name] || "default_value"`
