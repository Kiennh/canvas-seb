#!/bin/bash

# Usage: ./init_plugin.sh <plugin_name_snake_case>

if [ -z "$1" ]; then
  echo "Usage: $0 <plugin_name_snake_case>"
  exit 1
fi

PLUGIN_NAME_SNAKE=$1
PLUGIN_NAME_CAMEL=$(echo "$PLUGIN_NAME_SNAKE" | sed -r 's/(^|_)([a-z])/\U\2/g')
PLUGIN_NAME_HUMAN=$(echo "$PLUGIN_NAME_SNAKE" | sed 's/_/ /g' | sed -r 's/(^| )([a-z])/\U\2/g')
PLUGIN_DIR="gems/plugins/$PLUGIN_NAME_SNAKE"
SKILL_DIR=".agent/skills/canvas-plugin-init"

echo "Initializing plugin: $PLUGIN_NAME_HUMAN ($PLUGIN_NAME_SNAKE)"

# Create directories
mkdir -p "$PLUGIN_DIR/lib/$PLUGIN_NAME_SNAKE"
mkdir -p "$PLUGIN_DIR/app/controllers/$PLUGIN_NAME_SNAKE/api/v1"
mkdir -p "$PLUGIN_DIR/app/views/$PLUGIN_NAME_SNAKE/course_sample"
mkdir -p "$PLUGIN_DIR/app/views/$PLUGIN_NAME_SNAKE/errors"
mkdir -p "$PLUGIN_DIR/app/views/plugins"
mkdir -p "$PLUGIN_DIR/config"

# Helper function to replace placeholders and create file
generate_file() {
  local template=$1
  local target=$2
  sed "s/PLUGIN_NAME_SNAKE/$PLUGIN_NAME_SNAKE/g; s/PLUGIN_NAME_CAMEL/$PLUGIN_NAME_CAMEL/g; s/PLUGIN_NAME_HUMAN/$PLUGIN_NAME_HUMAN/g" "$SKILL_DIR/resources/templates/$template" > "$PLUGIN_DIR/$target"
}

# 1. Gemspec
generate_file "gemspec.ruby.template" "$PLUGIN_NAME_SNAKE.gemspec"

# 2. Version
echo "module $PLUGIN_NAME_CAMEL; VERSION = '1.0.0'; end" > "$PLUGIN_DIR/lib/$PLUGIN_NAME_SNAKE/version.rb"

# 3. Engine
generate_file "engine.ruby.template" "lib/$PLUGIN_NAME_SNAKE/engine.rb"

# 5. Settings partial (GUI)
generate_file "settings_partial.erb.template" "app/views/plugins/_${PLUGIN_NAME_SNAKE}_settings.html.erb"

# 6. API Controller
generate_file "api_controller.ruby.template" "app/controllers/${PLUGIN_NAME_SNAKE}/api/v1/${PLUGIN_NAME_SNAKE}_controller.rb"

# 7. Course Sample Controller
generate_file "course_sample_controller.ruby.template" "app/controllers/${PLUGIN_NAME_SNAKE}/course_sample_controller.rb"

# 8. Course Sample View
generate_file "course_sample_view.erb.template" "app/views/$PLUGIN_NAME_SNAKE/course_sample/index.html.erb"

# 9. Pre-routes
generate_file "pre_routes.ruby.template" "config/pre_routes.rb"

# 10. Worker
generate_file "worker.ruby.template" "lib/$PLUGIN_NAME_SNAKE/worker.rb"

# 11. System Extension (Hooks)
generate_file "quiz_extension.ruby.template" "lib/$PLUGIN_NAME_SNAKE/quiz_extension.rb"

# 12. Controller Extension
generate_file "quizzes_controller_extension.ruby.template" "lib/$PLUGIN_NAME_SNAKE/quizzes_controller_extension.rb"

# 13. Errors Controller
generate_file "errors_controller.ruby.template" "app/controllers/${PLUGIN_NAME_SNAKE}/errors_controller.rb"

# 14. Quiz Disabled View
generate_file "quiz_disabled_view.erb.template" "app/views/$PLUGIN_NAME_SNAKE/errors/quiz_disabled.html.erb"

# 4. Main lib (Updated to require all extensions)
echo "require \"$PLUGIN_NAME_SNAKE/engine\"
require \"$PLUGIN_NAME_SNAKE/quiz_extension\"
require \"$PLUGIN_NAME_SNAKE/quizzes_controller_extension\"
module $PLUGIN_NAME_CAMEL
end" > "$PLUGIN_DIR/lib/$PLUGIN_NAME_SNAKE.rb"

# Update Gemfile.d/plugins.rb
PLUGINS_RB="Gemfile.d/plugins.rb"
if grep -q "$PLUGIN_NAME_SNAKE" "$PLUGINS_RB"; then
  echo "Plugin already registered in $PLUGINS_RB"
else
  # Add to the inline_plugins list
  sed -i "/inline_plugins = %w\[/a \  $PLUGIN_NAME_SNAKE" "$PLUGINS_RB"
  echo "Registered plugin in $PLUGINS_RB"
fi

echo "Successfully initialized $PLUGIN_NAME_HUMAN at $PLUGIN_DIR"
