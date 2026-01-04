class PublicInsightsController < ApplicationController
  allow_unauthenticated_access

  layout "public"

  before_action :set_insight_item

  def show
    @current_file = if params[:file]
      @insight_item.insight_item_files.find_by(filename: params[:file])
    else
      @insight_item.entry_insight_item_file
    end
  end

  private

  def set_insight_item
    @insight_item = InsightItem.find_by(share_token: params[:token])

    unless @insight_item&.shareable?
      render "public_insights/not_found", status: :not_found
    end
  end
end
