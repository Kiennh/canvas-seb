# frozen_string_literal: true

module CanvasSeb
  class ErrorsController < ApplicationController
    before_action :require_user
    before_action :require_context

    def quiz_disabled
      @course_name = @context.respond_to?(:name) ? @context.name : "Unknown Course"
      @message = t(:quiz_disabled_message, "Quizzes are currently disabled by the Canvas SEB plugin for course '%{course}'.",
                   course: @course_name)
      render layout: 'application'
    end

    def quit
      @course_name = @context.respond_to?(:name) ? @context.name : "Unknown Course"
      render layout: 'application'
    end
  end
end
