class HomeController < ApplicationController
  def index
    @recent_reports = Report.published.includes(:user).order(published_at: :desc).limit(6)
    @total_reports = Report.count
    @published_reports = Report.published.count
    @user_reports = Current.user.reports.count
    @user_published = Current.user.reports.published.count
  end
end
