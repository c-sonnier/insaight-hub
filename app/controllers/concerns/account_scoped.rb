# frozen_string_literal: true

# AccountScoped concern handles multi-tenancy authorization
# Include this in controllers that require account context
module AccountScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_current_account
    before_action :require_account_membership
  end

  private

  def set_current_account
    # Account is set by middleware from URL path
    Current.account = request.env["insaight.account"]
  end

  def require_account_membership
    return if Current.account.nil? # Will be handled by routes/404

    # Super admins can access any account
    return if Current.super_admin?

    # Regular users need membership in the account
    unless Current.user
      redirect_to root_path, alert: "You don't have access to this organization."
    end
  end

  # Helper to scope queries to current account
  def current_account
    Current.account
  end

  # Check if current user is owner of the account
  def require_owner
    unless Current.owner?
      redirect_to root_path, alert: "This action requires owner permissions."
    end
  end
end
