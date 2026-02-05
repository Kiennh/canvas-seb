# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module CanvasSeb
  module MediaObjectsControllerExtension
    extend ActiveSupport::Concern

    included do
      before_action :inject_seb_media_player_assets, only: [:iframe_media_player]
    end

    private

    def inject_seb_media_player_assets
      # Check if SEB plugin is enabled in the plugin settings page
      plugin = Canvas::Plugin.find(:canvas_seb)
      
      if plugin&.enabled?
        plugin_settings = plugin.settings || {}
        hide_all_controls = Canvas::Plugin.value_to_boolean(plugin_settings[:hide_all_media_controls])
        disable_seek = Canvas::Plugin.value_to_boolean(plugin_settings[:disable_media_seek])

        # We only need to inject if at least one restriction is active
        if hide_all_controls || disable_seek
          # Add SEB flags to JS ENV
          js_env(
            SEB_ENABLED: true,
            SEB_HIDE_ALL_MEDIA_CONTROLS: hide_all_controls,
            SEB_DISABLE_MEDIA_SEEK: disable_seek
          )
          
          # Include SEB media player JS bundle
          js_bundle 'canvas_seb-media_player'
        end
      end
    end
  end
end
