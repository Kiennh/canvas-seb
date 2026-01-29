# frozen_string_literal: true

require_relative "version"

module CanvasSeb
  class Engine < ::Rails::Engine
    config.paths["lib"].eager_load!

    config.to_prepare do
      # Register the plugin with Canvas
      Canvas::Plugin.register :canvas_seb, nil, {
        name: -> { I18n.t(:canvas_seb_name, "Canvas SEB") },
        author: "Instructure",
        description: "Initializes CanvasSeb with GUI, API, Worker, and Course Navigation",
        version: CanvasSeb::VERSION,
        settings_partial: "plugins/canvas_seb_settings",
        settings: {
          enabled: true,
          worker: "CanvasSeb::Worker",
          disable_quiz_start: false
        }
      }

      # Register granular permissions
      Permissions.register({
        view_canvas_seb_sample_page: {
          label: -> { I18n.t("Permissions - View Canvas SEB Config Page") },
          available_to: %w[StudentEnrollment TeacherEnrollment TaEnrollment DesignerEnrollment AccountMembership],
          true_for: %w[TeacherEnrollment TaEnrollment AccountAdmin],
        },
        manage_canvas_seb_course_settings: {
          label: -> { I18n.t("Permissions - Manage Canvas SEB Course Settings") },
          available_to: %w[TeacherEnrollment TaEnrollment DesignerEnrollment AccountMembership],
          true_for: %w[TeacherEnrollment TaEnrollment AccountAdmin],
        }
      })

      # Extend Course navigation
      Course.prepend(CanvasSeb::CourseExtension)

      # Register System Hooks
      Quizzes::Quiz.prepend(CanvasSeb::QuizExtension)

      # Register Controller Hooks
      Quizzes::QuizzesController.prepend(CanvasSeb::QuizzesControllerExtension)
    end
  end

  module CourseExtension
    def tabs_available(user = nil, opts = {})
      tabs = super
      if self.grants_right?(user, :view_canvas_seb_sample_page)
        tabs << {
          id: "canvas_seb_sample",
          label: I18n.t("Canvas SEB config"),
          css_class: "canvas_seb_sample",
          href: :course_canvas_seb_sample_path,
          visibility: "members"
        }.with_indifferent_access
      end
      tabs
    end
  end
end
