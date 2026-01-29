# frozen_string_literal: true

module CanvasSeb
  module QuizExtension
    # Hook into Canvas Quiz generation
    # This is called whenever a student (or preview user) starts a quiz
    def generate_submission(user, preview = false)
      Rails.logger.info "[Canvas SEB] generate_submission"
      # Access captured request info from Thread.current (set in QuizzesControllerExtension)
      req_info = Thread.current[:canvas_seb_request_info] || {}
      user_agent = req_info[:user_agent] || "Unknown UA"
      remote_ip = req_info[:remote_ip] || "Unknown IP"

      # Get plugin settings and course info
      settings = Canvas::Plugin.find(:canvas_seb).settings || {}
      course_name = self.context.respond_to?(:name) ? self.context.name : "Unknown Course"
      
      # Check if "Disable Quiz SEB" (Enforce SEB) is enabled in settings
      if Canvas::Plugin.value_to_boolean(settings[:disable_quiz_seb]) && !preview
        # Check SEB Config Key if configured for the course
        mac_key = self.context.settings[:seb_config_key_mac] || self.context.settings[:canvas_seb_quiz_key]
        win_key = self.context.settings[:seb_config_key_window]

        if mac_key.present? || win_key.present?
          headers = req_info[:headers] || {}
          client_seb_hash = headers['HTTP_X_SAFEEXAMBROWSER_CONFIGKEYHASH']
          current_url = req_info[:current_url].to_s

          require 'digest'
          valid_hashes = []
          valid_hashes << Digest::SHA256.hexdigest(current_url + mac_key) if mac_key.present?
          valid_hashes << Digest::SHA256.hexdigest(current_url + win_key) if win_key.present?

          if !client_seb_hash.to_s.empty? && valid_hashes.include?(client_seb_hash)
            # Match
          else
            Rails.logger.info "[Canvas SEB] SEB Config Key mismatch. Valid Hashes: #{valid_hashes.join(', ')}, Received Hash: #{client_seb_hash} (URL: #{current_url}) for user #{user.id}"
            raise "This quiz requires Safe Exam Browser with the correct configuration. (Mismatch detected)"
          end
        else
          # Fallback: Validation enabled but no keys set -> Block all
          Rails.logger.info "[Canvas SEB] Preventing quiz start (No SEB keys configured) for user #{user.id} in course '#{course_name}'"
          raise "Quizzes are currently disabled by the Canvas SEB plugin for course '#{course_name}'."
        end
      end

      # Custom logic: Log the start of a quiz
      Rails.logger.info "[Canvas SEB] Hook triggered: User #{user.is_a?(User) ? user.name : user} is starting quiz '#{self.title}' (ID: #{self.id})"
      Rails.logger.info "[Canvas SEB] Request Details: IP=#{remote_ip}, UA=#{user_agent}"
      
      super # CRITICAL: Call super to maintain standard Canvas behavior
    end
  end
end
