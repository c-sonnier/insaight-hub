module Admin
  class BaseController < ApplicationController
    include AccountScoped

    before_action :require_admin_or_owner

    private

    # Admin area is accessible to:
    # - Account owners (for their own account)
    # - Super admins (identity.admin? - can access any account)
    def require_admin_or_owner
      unless Current.owner? || Current.super_admin?
        redirect_to root_path, alert: "You are not authorized to access this area."
      end
    end

    # Helper to check if current user is a super admin
    def super_admin?
      Current.super_admin?
    end
    helper_method :super_admin?
  end
end
