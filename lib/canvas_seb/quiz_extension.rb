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
        course_seb_key = self.context.settings[:canvas_seb_quiz_key]

        if course_seb_key.present?
          headers = req_info[:headers] || {}
          client_seb_hash = headers['HTTP_X_SAFEEXAMBROWSER_CONFIGKEYHASH']
          current_url = req_info[:current_url].to_s

          require 'digest'
          expected_hash = Digest::SHA256.hexdigest(current_url + course_seb_key)

          if client_seb_hash != expected_hash
            Rails.logger.info "[Canvas SEB] SEB Config Key mismatch. Expected Hash: #{expected_hash}, Received Hash: #{client_seb_hash} (Based on URL: #{current_url} and Course Key: #{course_seb_key}) for user #{user.id}"
            
            # For debugging purposes, we might want to show the expected hash or parts of it
            raise "This quiz requires Safe Exam Browser with the correct configuration. (Mismatch detected)"
          end
        else
          # Fallback: Validation enabled but no key set -> Block all
          Rails.logger.info "[Canvas SEB] Preventing quiz start (No SEB key configured) for user #{user.id} in course '#{course_name}'"
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
