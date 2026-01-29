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
        course_seb_key = @context.settings[:canvas_seb_quiz_key]
        
        if course_seb_key.present?
          client_seb_hash = request.headers['X-SafeExamBrowser-ConfigKeyHash']
          current_url = request.original_url
          
          require 'digest'
          expected_hash = Digest::SHA256.hexdigest(current_url + course_seb_key)
          
          Rails.logger.info "[Canvas SEB] SEB Validation - URL: #{current_url}"
          Rails.logger.info "[Canvas SEB] SEB Validation - Course Key: #{course_seb_key}"
          Rails.logger.info "[Canvas SEB] SEB Validation - Expected Hash: #{expected_hash}"
          Rails.logger.info "[Canvas SEB] SEB Validation - Received Hash: #{client_seb_hash || 'MISSING'}"

          if client_seb_hash.present? && client_seb_hash == expected_hash
            Rails.logger.info "[Canvas SEB] SEB Validation - MATCH! Access granted."
            return
          else
            Rails.logger.warn "[Canvas SEB] SEB Validation - MISMATCH or MISSING. Redirecting."
          end
        else
          Rails.logger.warn "[Canvas SEB] SEB Validation - No key configured for course #{@context.id}. Redirecting."
        end

        redirect_to canvas_seb_quiz_disabled_path(course_id: @context.id)
      end
    end
  end
end
