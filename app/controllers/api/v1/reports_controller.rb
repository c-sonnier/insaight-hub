module Api
  module V1
    class ReportsController < BaseController
      before_action :set_report, only: [:show, :update, :destroy, :publish, :unpublish]
      before_action :authorize_owner, only: [:update, :destroy, :publish, :unpublish]

      def index
        @reports = current_user.reports

        @reports = @reports.where(status: params[:status]) if params[:status].present?
        @reports = @reports.by_audience(params[:audience]) if params[:audience].present?
        @reports = @reports.by_tag(params[:tag]) if params[:tag].present?
        @reports = @reports.search(params[:q]) if params[:q].present?

        @reports = @reports.order(created_at: :desc)
        @pagy, @reports = pagy(@reports, items: params[:per_page] || 20)

        render json: {
          reports: @reports.map { |r| report_json(r) },
          pagination: pagy_metadata(@pagy)
        }
      end

      def show
        render json: report_json(@report, include_files: true)
      end

      def create
        @report = current_user.reports.build(report_create_params)

        # Handle single-file creation via content parameter
        if params[:content].present? && @report.report_files.empty?
          @report.report_files.build(
            filename: params[:filename] || "index.html",
            content: params[:content],
            content_type: params[:content_type] || "text/html"
          )
        end

        if @report.save
          render json: report_json(@report, include_files: true), status: :created
        else
          render json: { errors: @report.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @report.update(report_update_params)
          render json: report_json(@report, include_files: true)
        else
          render json: { errors: @report.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @report.destroy
        head :no_content
      end

      def publish
        @report.publish!
        render json: report_json(@report)
      end

      def unpublish
        @report.unpublish!
        render json: report_json(@report)
      end

      private

      def set_report
        @report = current_user.reports.find_by!(slug: params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Report not found" }, status: :not_found
      end

      def authorize_owner
        unless @report.user == current_user
          render json: { error: "Forbidden" }, status: :forbidden
        end
      end

      def report_create_params
        params.permit(:title, :description, :audience, :entry_file, tags: [],
          files: [:filename, :content, :content_type]).tap do |permitted|
          # Handle files array for multi-file creation
          if params[:files].present?
            permitted[:report_files_attributes] = params[:files].map do |file|
              {
                filename: file[:filename],
                content: file[:content],
                content_type: file[:content_type] || "text/html"
              }
            end
          end
          permitted.delete(:files)

          # Handle tags as comma-separated string or array
          if params[:tags].is_a?(String)
            permitted[:tags] = params[:tags]
          end
        end
      end

      def report_update_params
        params.permit(:title, :description, :audience, :entry_file, tags: [],
          files: [:id, :filename, :content, :content_type, :_destroy]).tap do |permitted|
          if params[:files].present?
            permitted[:report_files_attributes] = params[:files]
          end
          permitted.delete(:files)

          if params[:tags].is_a?(String)
            permitted[:tags] = params[:tags]
          end
        end
      end

      def report_json(report, include_files: false)
        result = {
          id: report.id,
          slug: report.slug,
          title: report.title,
          description: report.description,
          audience: report.audience,
          status: report.status,
          tags: report.tags,
          entry_file: report.entry_file,
          published_at: report.published_at,
          created_at: report.created_at,
          updated_at: report.updated_at
        }

        if include_files
          result[:files] = report.report_files.map do |file|
            {
              id: file.id,
              filename: file.filename,
              content: file.content,
              content_type: file.content_type
            }
          end
        else
          result[:files_count] = report.report_files.count
        end

        result
      end
    end
  end
end
