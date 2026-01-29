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
          # Generate a unique session token for this specific login
          session_token = SecureRandom.uuid
          session[:canvas_seb_session_token] = session_token

          # Update the authorized session token for this user in the cache
          Rails.logger.info "[Canvas SEB] Single Session - Recording new session token for user #{user.id}: #{session_token}"
          Rails.cache.write("user_single_session_#{user.id}", session_token)
        end
      end
    end
  end
end
