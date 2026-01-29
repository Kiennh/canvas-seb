module CanvasSeb
  module Api
    module V1
      class CanvasSebController < ApplicationController
        before_action :require_user

        # GET /api/v1/canvas_seb
        def index
          render json: { 
            status: 'success', 
            message: "Hello from Canvas SEB API, #{@current_user.name}!",
            plugin_id: 'canvas_seb'
          }
        end

        # POST /api/v1/canvas_seb/trigger_worker
        def trigger_worker
          worker_id = SecureRandom.uuid
          CanvasSeb::Worker.enqueue(worker_id)
          render json: { 
            status: 'success', 
            message: 'Worker job enqueued', 
            job_id: worker_id 
          }
        end
      end
    end
  end
end
