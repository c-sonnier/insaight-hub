class InsightItemFilesController < ApplicationController
  def show
    @insight_item = InsightItem.find_by!(slug: params[:insight_item_id])
    @insight_item_file = @insight_item.insight_item_files.find_by!(filename: params[:id])

    unless @insight_item.published? || @insight_item.user == Current.user || Current.user&.admin?
      head :not_found
      return
    end

    render html: @insight_item_file.content.html_safe, content_type: @insight_item_file.content_type
  end
end
