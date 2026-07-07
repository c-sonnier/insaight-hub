# frozen_string_literal: true

# AccountScoped concern handles multi-tenancy authorization
# Include this in controllers that require account context
module AccountScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_current_account
    before_action :require_account_membership
    helper_method :current_account
  end

  private

  def set_current_account
    Current.account = request.env["insaight.account"]
    track_last_account
  end

  def require_account_membership
    return redirect_to_account_scoped_path if Current.account.nil?

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

  # Requests without an account prefix (e.g. native tab paths like /dashboard)
  # get redirected to the same path under the identity's account.
  def redirect_to_account_scoped_path
    account = Current.identity&.last_account || Current.identity&.accounts&.first
    if account
      redirect_to "/#{account.external_id}#{request.fullpath}"
    else
      redirect_to new_account_path
    end
  end

  def track_last_account
    return unless Current.account && Current.identity
    return if Current.identity.last_account_id == Current.account.id

    Current.identity.update_column(:last_account_id, Current.account.id)
  end
end
