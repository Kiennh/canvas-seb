# frozen_string_literal: true

module CanvasSeb
  class ErrorsController < ApplicationController
    before_action :require_user
    before_action :require_context

    def quiz_disabled
      @remote_ip = request.remote_ip
      @user_agent = request.user_agent
      @course_name = @context.respond_to?(:name) ? @context.name : "Unknown Course"
      @course_key = @context.respond_to?(:settings) ? @context.settings[:canvas_seb_quiz_key].presence : nil
      @client_seb_key = request.headers['X-SafeExamBrowser-ConfigKeyHash']
      @current_url = request.original_url

      # Debug: Find all headers containing SafeExamBrowser
      seb_headers = []
      request.headers.each do |k, v|
        seb_headers << "#{k}: #{v}" if k.to_s.downcase.include?('safeexambrowser')
      end
      seb_headers_debug = seb_headers.join(" | ")
      
      require 'digest'
      @expected_hash = @course_key.present? ? Digest::SHA256.hexdigest(@current_url + @course_key) : "N/A"

      seb_debug_text = " [URL: #{@current_url}] [Course Key: #{@course_key || 'None'}] [Expected Hash: #{@expected_hash}]"
      seb_header_text = seb_headers_debug.present? ? " [SEB Headers: #{seb_headers_debug}]" : " [No SEB Headers found]"

      key_text = @course_key ? " (Course Key: #{@course_key})" : ""
      client_key_text = " (Client Key: #{@client_seb_key.presence || 'None'})"

      @message = t(:quiz_disabled_message, "Quizzes are currently disabled by the Canvas SEB plugin for course '%{course}'.%{key_text}%{client_key_text}%{seb_debug_text}%{seb_header_text} (Your IP: %{ip}, User-Agent: %{ua})",
                   course: @course_name, key_text: key_text, client_key_text: client_key_text, 
                   seb_debug_text: seb_debug_text, seb_header_text: seb_header_text, ip: @remote_ip, ua: @user_agent)
      render layout: 'application'
    end
  end
end
