module Api
  module V1
    class InsightItemsController < BaseController
      before_action :set_insight_item, only: [:show, :update, :destroy, :publish, :unpublish]
      before_action :authorize_owner, only: [:update, :destroy, :publish, :unpublish]

      def index
        @insight_items = current_user.insight_items

        @insight_items = @insight_items.where(status: params[:status]) if params[:status].present?
        @insight_items = @insight_items.by_audience(params[:audience]) if params[:audience].present?
        @insight_items = @insight_items.by_tag(params[:tag]) if params[:tag].present?
        @insight_items = @insight_items.search(params[:q]) if params[:q].present?

        @insight_items = @insight_items.order(created_at: :desc)
        @pagy, @insight_items = pagy(@insight_items, items: params[:per_page] || 20)

        render json: {
          insight_items: @insight_items.map { |r| insight_item_json(r) },
          pagination: pagy_metadata(@pagy)
        }
      end

      def show
        render json: insight_item_json(@insight_item, include_files: true)
      end

      def create
        @insight_item = current_user.insight_items.build(insight_item_create_params)

        # Handle single-file creation via content parameter
        if params[:content].present? && @insight_item.insight_item_files.empty?
          @insight_item.insight_item_files.build(
            filename: params[:filename] || "index.html",
            content: params[:content],
            content_type: params[:content_type] || "text/html"
          )
        end

        if @insight_item.save
          render json: insight_item_json(@insight_item, include_files: true), status: :created
        else
          render json: { errors: @insight_item.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @insight_item.update(insight_item_update_params)
          render json: insight_item_json(@insight_item, include_files: true)
        else
          render json: { errors: @insight_item.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @insight_item.destroy
        head :no_content
      end

      def publish
        @insight_item.publish!
        render json: insight_item_json(@insight_item)
      end

      def unpublish
        @insight_item.unpublish!
        render json: insight_item_json(@insight_item)
      end

      private

      def set_insight_item
        @insight_item = current_user.insight_items.find_by!(slug: params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Insight not found" }, status: :not_found
      end

      def authorize_owner
        unless @insight_item.user == current_user
          render json: { error: "Forbidden" }, status: :forbidden
        end
      end

      def insight_item_create_params
        params.permit(:title, :description, :audience, :entry_file, tags: [],
          files: [:filename, :content, :content_type]).tap do |permitted|
          # Handle files array for multi-file creation
          if params[:files].present?
            permitted[:insight_item_files_attributes] = params[:files].map do |file|
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

      def insight_item_update_params
        params.permit(:title, :description, :audience, :entry_file, tags: [],
          files: [:id, :filename, :content, :content_type, :_destroy]).tap do |permitted|
          if params[:files].present?
            permitted[:insight_item_files_attributes] = params[:files]
          end
          permitted.delete(:files)

          if params[:tags].is_a?(String)
            permitted[:tags] = params[:tags]
          end
        end
      end

      def insight_item_json(insight_item, include_files: false)
        result = {
          id: insight_item.id,
          slug: insight_item.slug,
          title: insight_item.title,
          description: insight_item.description,
          audience: insight_item.audience,
          status: insight_item.status,
          tags: insight_item.tags,
          entry_file: insight_item.entry_file,
          published_at: insight_item.published_at,
          created_at: insight_item.created_at,
          updated_at: insight_item.updated_at
        }

        if include_files
          result[:files] = insight_item.insight_item_files.map do |file|
            {
              id: file.id,
              filename: file.filename,
              content: file.content,
              content_type: file.content_type
            }
          end
        else
          result[:files_count] = insight_item.insight_item_files.count
        end

        result
      end
    end
  end
end
