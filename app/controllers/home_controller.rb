class HomeController < ApplicationController
  def index
    @recent_insights = InsightItem.published.includes(:user).order(published_at: :desc).limit(6)
    @total_insights = InsightItem.count
    @published_insights = InsightItem.published.count
    @user_insights = Current.user.insight_items.count
    @user_published = Current.user.insight_items.published.count
    @user_drafts = @user_insights - @user_published
  end
end
