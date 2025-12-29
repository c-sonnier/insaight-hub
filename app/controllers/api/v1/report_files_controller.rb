module Api
  module V1
    class ReportFilesController < BaseController
      before_action :set_report
      before_action :set_file, only: [:destroy]

      def destroy
        @file.destroy
        head :no_content
      end

      private

      def set_report
        @report = current_user.reports.find_by!(slug: params[:report_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Report not found" }, status: :not_found
      end

      def set_file
        @file = @report.report_files.find_by!(filename: params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "File not found" }, status: :not_found
      end
    end
  end
end
