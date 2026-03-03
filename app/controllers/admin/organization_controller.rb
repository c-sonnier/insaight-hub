module Admin
  class OrganizationController < BaseController
    def show
      @account = current_account
      @users = @account.users.includes(:identity).order(created_at: :desc)
      @invites = @account.invites.includes(created_by: :identity, used_by: :identity).order(created_at: :desc)
      @tab = params[:tab].presence || "members"
    end
  end
end
