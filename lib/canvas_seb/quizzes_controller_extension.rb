# frozen_string_literal: true

module CanvasSeb
  module QuizzesControllerExtension
    def self.prepended(base)
      base.before_action :capture_canvas_seb_request_info, only: [:show, :start_quiz!]
      base.before_action :check_canvas_seb_quiz_disabled, only: [:show, :start_quiz!]
    end

    def capture_canvas_seb_request_info
      # Store the user agent or specific headers in a thread-local variable
      Thread.current[:canvas_seb_request_info] = {
        user_agent: request.user_agent,
        remote_ip: request.remote_ip,
        current_url: request.original_url,
        # In Rails controllers, we can access headers via request.headers
        headers: {
          'HTTP_X_SAFEEXAMBROWSER_CONFIGKEYHASH' => request.headers['X-SafeExamBrowser-ConfigKeyHash']
        }
      }
    end

    def check_canvas_seb_quiz_disabled
      settings = Canvas::Plugin.find(:canvas_seb).settings || {}
      enabled = Canvas::Plugin.value_to_boolean(settings[:disable_quiz_seb])
      
      if enabled && @quiz.present? && !can_preview?
        mac_key = @context.settings[:seb_config_key_mac] || @context.settings[:canvas_seb_quiz_key]
        win_key = @context.settings[:seb_config_key_window]
        
        if mac_key.present? || win_key.present?
          client_seb_hash = request.headers['X-SafeExamBrowser-ConfigKeyHash']
          current_url = request.original_url
          
          require 'digest'
          
          valid_hashes = []
          valid_hashes << Digest::SHA256.hexdigest(current_url + mac_key) if mac_key.present?
          valid_hashes << Digest::SHA256.hexdigest(current_url + win_key) if win_key.present?
          
          Rails.logger.info "[Canvas SEB] SEB Validation - URL: #{current_url}"
          Rails.logger.info "[Canvas SEB] SEB Validation - MAC Key: #{mac_key}"
          Rails.logger.info "[Canvas SEB] SEB Validation - Win Key: #{win_key}"
          Rails.logger.info "[Canvas SEB] SEB Validation - Valid Hashes: #{valid_hashes.join(', ')}"
          Rails.logger.info "[Canvas SEB] SEB Validation - Received Hash: #{client_seb_hash || 'MISSING'}"

          if client_seb_hash.present? && valid_hashes.include?(client_seb_hash)
            Rails.logger.info "[Canvas SEB] SEB Validation - MATCH! Access granted."
            return
          else
            Rails.logger.warn "[Canvas SEB] SEB Validation - MISMATCH or MISSING. Redirecting."
          end
        else
          Rails.logger.warn "[Canvas SEB] SEB Validation - No keys configured for course #{@context.id}. Redirecting."
        end

        redirect_to canvas_seb_quiz_disabled_path(course_id: @context.id)
      end
    end
  end
end
