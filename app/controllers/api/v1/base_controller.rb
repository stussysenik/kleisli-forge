module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_user!

      private

      def authenticate_api_user!
        api_key = request.headers["Authorization"]&.sub("Bearer ", "")
        @current_user = User.find_by(api_key: api_key)

        render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
      end

      def current_user
        @current_user
      end
    end
  end
end
