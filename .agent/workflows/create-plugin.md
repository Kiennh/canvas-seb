---
description: create workflows to build a new plugin for canvas
---

# Building a New Plugin for Canvas LMS

This workflow guides you through the process of creating and registering a new plugin within the Canvas LMS ecosystem.

## Step 1: Initialize Plugin Directory
Create the base directory structure for your plugin in `gems/plugins/`.

// turbo
```bash
PLUGIN_NAME="my_new_plugin"
mkdir -p gems/plugins/$PLUGIN_NAME/lib/$PLUGIN_NAME
mkdir -p gems/plugins/$PLUGIN_NAME/app
```

## Step 2: Create Gemspec
Define the gem specification for your plugin. Create `gems/plugins/<plugin_name>/<plugin_name>.gemspec`.

```ruby
# frozen_string_literal: true

require_relative "lib/my_new_plugin/version"

Gem::Specification.new do |spec|
  spec.name          = "my_new_plugin"
  spec.version       = MyNewPlugin::VERSION
  spec.authors       = ["Instructure"]
  spec.email         = ["info@instructure.com"]
  spec.summary       = "Summary of My New Plugin"
  spec.description   = "Detailed description of My New Plugin"
  spec.homepage      = "http://www.instructure.com"

  spec.files         = Dir["{app,lib}/**/*"]

  spec.add_dependency "rails", ">= 3.2"
end
```

## Step 3: Define Version
Create `gems/plugins/my_new_plugin/lib/my_new_plugin/version.rb`.

```ruby
# frozen_string_literal: true

module MyNewPlugin
  VERSION = "1.0.0"
end
```

## Step 4: Create the Rails Engine
Create `gems/plugins/my_new_plugin/lib/my_new_plugin/engine.rb`. This is where the plugin registers itself with Canvas.

```ruby
# frozen_string_literal: true

module MyNewPlugin
  class Engine < ::Rails::Engine
    isolate_namespace MyNewPlugin

    config.paths["lib"].eager_load!

    config.to_prepare do
      Canvas::Plugin.register :my_new_plugin, :other, {
        name: -> { I18n.t(:my_new_plugin_name, "My New Plugin") },
        author: "Instructure",
        description: "What this plugin does",
        version: "1.0.0"
      }
    end
  end
end
```

## Step 5: Main Entry Point
Create `gems/plugins/my_new_plugin/lib/my_new_plugin.rb`.

```ruby
# frozen_string_literal: true

require "my_new_plugin/engine"

module MyNewPlugin
end
```

## Step 6: Register in Gemfile
Add your plugin to the `inline_plugins` list in `Gemfile.d/plugins.rb` to ensure it is loaded.

1. Open `Gemfile.d/plugins.rb`.
2. Add `"my_new_plugin"` to the `inline_plugins` array.

## Step 7: Implementation (Example: Migration Provider)
If you are building a migration/import plugin (like Moodle Importer), inherit from `Canvas::Migration::Migrator`.

Example `lib/my_new_plugin/converter.rb`:
```ruby
module MyNewPlugin
  class Converter < Canvas::Migration::Migrator
    def initialize(settings)
      super(settings, "my_new_plugin")
    end

    def export
      # Implementation logic for exporting/converting data
    end
  end
end
```

## Step 8: Testing
Create a `spec_canvas` directory for your tests.
```bash
mkdir -p gems/plugins/my_new_plugin/spec_canvas
```

Run tests using:
```bash
bundle exec rspec gems/plugins/my_new_plugin/spec_canvas
```