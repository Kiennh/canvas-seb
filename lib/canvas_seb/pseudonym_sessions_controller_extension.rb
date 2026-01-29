# frozen_string_literal: true

module CanvasSeb
  module PseudonymSessionsControllerExtension
    def create
      super
      # If login was successful, current_user should be set (it might be in @current_user or current_user)
      user = @current_user || (respond_to?(:current_user) && current_user)
      if user
        settings = Canvas::Plugin.find(:canvas_seb).settings || {}
        if Canvas::Plugin.value_to_boolean(settings[:single_session])
          # Update the authorized session ID for this user
          Rails.logger.info "[Canvas SEB] Single Session - Recording new session ID for user #{user.id}"
          Rails.cache.write("user_single_session_#{user.id}", session.id.to_s)
        end
      end
    end
  end
end
