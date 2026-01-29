CanvasRails::Application.routes.draw do
  # Plugin API Routes
  namespace :api do
    namespace :v1 do
      get 'canvas_seb' => 'canvas_seb/api/v1/canvas_seb#index'
      post 'canvas_seb/trigger_worker' => 'canvas_seb/api/v1/canvas_seb#trigger_worker'
    end
  end

  # Course Navigation Page Route
  get 'courses/:id/canvas_seb_sample' => 'canvas_seb/course_sample#index', as: :course_canvas_seb_sample
  post 'courses/:id/canvas_seb_save_settings' => 'canvas_seb/course_sample#save_settings', as: :course_canvas_seb_save_settings

  # Error Pages
  get 'canvas_seb/quiz_disabled' => 'canvas_seb/errors#quiz_disabled', as: :canvas_seb_quiz_disabled
end
