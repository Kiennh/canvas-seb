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

      current_token = session[:canvas_seb_session_token]
      
      cache_key = "user_single_session_#{user.id}"
      authorized_token = Rails.cache.read(cache_key)

      # If there's an authorized token in cache but it doesn't match our session token, force logout
      if authorized_token.present? && authorized_token != current_token
        Rails.logger.warn "[Canvas SEB] Single Session - Token mismatch for user #{user.id}. Session Token: #{current_token || 'MISSING'}, Authorized Token: #{authorized_token}. Forcing logout."
        
        # Force logout
        if respond_to?(:logout_current_user, true)
          logout_current_user
        else
          reset_session
        end

        flash[:error] = I18n.t(:single_session_error, "Your session has been terminated because you logged in from another browser.")
        redirect_to login_url
      elsif authorized_token.blank? && current_token.present?
        # If for some reason the cache is empty but we have a token, re-populate the cache
        Rails.cache.write(cache_key, current_token)
      elsif current_token.blank?
        # If the user is logged in but has no token (e.g. they were logged in before the plugin was enabled)
        # We should probably assign them a token now to start enforcement
        new_token = SecureRandom.uuid
        session[:canvas_seb_session_token] = new_token
        Rails.cache.write(cache_key, new_token)
      end
    end
  end
end
