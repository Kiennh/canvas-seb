# frozen_string_literal: true

module CanvasSeb
  module ApplicationControllerExtension
    def self.prepended(base)
      base.before_action :enforce_single_session
    end

    def enforce_single_session
      # We only care if a user is logged in
      user = @current_user || (respond_to?(:current_user) && current_user)
      return unless user

      settings = Canvas::Plugin.find(:canvas_seb).settings || {}
      return unless Canvas::Plugin.value_to_boolean(settings[:single_session])

      # Skip if this is the login/logout process to avoid recursion or blocking login
      return if controller_name == 'pseudonym_sessions'

      current_session_id = session.id.to_s
      return if current_session_id.blank?

      cache_key = "user_single_session_#{user.id}"
      authorized_session_id = Rails.cache.read(cache_key)

      if authorized_session_id.nil?
        # If no session is recorded yet, record the current one
        Rails.cache.write(cache_key, current_session_id)
      elsif authorized_session_id != current_session_id
        # Mismatch detected! This means another session has been authorized since this session started.
        Rails.logger.warn "[Canvas SEB] Single Session - Session mismatch for user #{user.id}. Current: #{current_session_id}, Authorized: #{authorized_session_id}. Forcing logout."
        
        # Force logout
        if respond_to?(:logout_current_user, true)
          logout_current_user
        else
          reset_session
        end

        flash[:error] = I18n.t(:single_session_error, "Your session has been terminated because you logged in from another browser.")
        redirect_to login_url
      end
    end
  end
end
