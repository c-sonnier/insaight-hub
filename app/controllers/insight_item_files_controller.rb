class InsightItemFilesController < ApplicationController
  allow_unauthenticated_access only: [:show]

  def show
    @insight_item = InsightItem.find_by!(slug: params[:insight_item_id])
    @insight_item_file = @insight_item.insight_item_files.find_by!(filename: params[:id])

    # For published insights, allow public access
    # For draft insights, require ownership or admin
    unless @insight_item.published? || @insight_item.user == Current.user || Current.user&.admin?
      head :not_found
      return
    end

    render html: @insight_item_file.content.html_safe, content_type: @insight_item_file.content_type
  end
end
