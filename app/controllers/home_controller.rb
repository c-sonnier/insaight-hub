class HomeController < ApplicationController
  include AccountScoped

  allow_unauthenticated_access only: [:index, :how_to]
  skip_before_action :set_current_account, only: [:index, :how_to]
  skip_before_action :require_account_membership, only: [:index, :how_to]

  def index
    if authenticated?
      # Redirect to first account's dashboard
      if Current.identity&.accounts&.any?
        account = Current.identity.accounts.first
        redirect_to "/#{account.external_id}/dashboard"
      else
        redirect_to root_path
      end
    else
      render :landing
    end
  end

  def dashboard
    # All queries scoped to current account
    @recent_insights = current_account.insight_items.published.includes(user: :identity).order(published_at: :desc).limit(6)
    @total_insights = current_account.insight_items.count
    @published_insights = current_account.insight_items.published.count
    @user_insights = Current.user&.insight_items&.count || 0
    @user_published = Current.user&.insight_items&.published&.count || 0
    @user_drafts = @user_insights - @user_published
  end

  def how_to
  end
end
