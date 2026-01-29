module CanvasSeb
  class CourseSampleController < ApplicationController
    prepend_before_action :set_course_id
    before_action :get_context
    before_action :require_user
    protect_from_forgery with: :exception

    def set_course_id
      params[:course_id] ||= params[:id]
    end

    def index
      if authorized_action(@context, @current_user, :view_canvas_seb_sample_page)
        @username = @current_user.name
        @coursename = @context.name
        @course_key = @context.settings[:canvas_seb_quiz_key]
      end
    end

    def save_settings
      if authorized_action(@context, @current_user, :manage_canvas_seb_course_settings)
        # Create a deep mutable copy of settings to avoid frozen hash errors
        current_settings = (@context.settings || {}).deep_dup
        current_settings[:canvas_seb_quiz_key] = params[:course_quiz_key]
        
        Rails.logger.info "[Canvas SEB] Saving course key: #{params[:course_quiz_key]} for course #{@context.id}"
        
        # Use update_attribute to bypass validations and ensure save
        if @context.update_attribute(:settings, current_settings)
          Rails.logger.info "[Canvas SEB] Successfully saved course key"
          flash[:notice] = t(:settings_saved, "Course settings saved successfully.")
        else
          Rails.logger.error "[Canvas SEB] Failed to save course key: #{@context.errors.full_messages}"
          flash[:error] = t(:settings_failed, "Failed to save course settings.")
        end
        redirect_to course_canvas_seb_sample_path(id: @context.id)
      end
    end
  end
end
