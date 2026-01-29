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
      return if controller_name == 'pseudonym_sessions' || controller_name == 'login' || controller_path.to_s.start_with?('login/')

      current_token = session[:canvas_seb_session_token]
      
      cache_key = "user_single_session_#{user.id}"
      authorized_token = MultiCache.cache.read(cache_key)

      Rails.logger.info "[Canvas SEB] Single Session - User: #{user.id}, Session Token: #{current_token.inspect}, Authorized Token: #{authorized_token.inspect}"

      # If there's an authorized token in cache but it doesn't match our session token, force logout.
      # We only force logout if the current session ALREADY has a token. 
      # If current_token is blank, it's a new session that should be allowed to take over (invalidate the old one).
      if current_token.present? && authorized_token.present? && authorized_token != current_token
        Rails.logger.warn "[Canvas SEB] Single Session - Token mismatch for user #{user.id}. Session Token: #{current_token}, Authorized Token: #{authorized_token}. Forcing logout."
        
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
        MultiCache.cache.write(cache_key, current_token)
      elsif current_token.blank?
        # If the user is logged in but has no token (e.g. new session or plugin just enabled)
        # We assign them a new token and update the cache, which will invalidate any previous sessions.
        new_token = SecureRandom.uuid
        session[:canvas_seb_session_token] = new_token
        MultiCache.cache.write(cache_key, new_token)
        Rails.logger.info "[Canvas SEB] Single Session - New session takeover for user #{user.id}. New Token: #{new_token}"
      end
    end
  end
end
