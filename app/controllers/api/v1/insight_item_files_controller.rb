module Api
  module V1
    class InsightItemFilesController < BaseController
      before_action :set_insight_item
      before_action :set_file, only: [:destroy]

      def destroy
        @file.destroy
        head :no_content
      end

      private

      def set_insight_item
        @insight_item = current_user.insight_items.find_by!(slug: params[:insight_item_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Insight not found" }, status: :not_found
      end

      def set_file
        @file = @insight_item.insight_item_files.find_by!(filename: params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "File not found" }, status: :not_found
      end
    end
  end
end
