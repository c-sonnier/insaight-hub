module Admin
  class WaitlistEntriesController < BaseController
    # Waitlist is global (not account-scoped), only super admins can manage it
    skip_before_action :set_current_account
    skip_before_action :require_account_membership
    skip_before_action :require_admin_or_owner
    before_action :require_super_admin

    def index
      @waitlist_entries = WaitlistEntry.order(created_at: :desc)
    end

    def destroy
      @waitlist_entry = WaitlistEntry.find(params[:id])
      @waitlist_entry.destroy
      redirect_to admin_waitlist_entries_path, notice: "Entry removed from waitlist."
    end

    private

    def require_super_admin
      unless Current.super_admin?
        redirect_to root_path, alert: "You are not authorized to access this area."
      end
    end
  end
end
