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

    def approve
      @waitlist_entry = WaitlistEntry.find(params[:id])

      ActiveRecord::Base.transaction do
        # Create the organization account
        account = Account.create!(name: "#{@waitlist_entry.name}'s Organization")

        # Create the identity (user will set password via email link)
        identity = Identity.create!(
          name: @waitlist_entry.name,
          email_address: @waitlist_entry.email,
          password: SecureRandom.hex(32) # Temporary password, user will reset via email
        )

        # Create membership as organization owner
        User.create!(
          account: account,
          identity: identity,
          role: :owner
        )

        # Send welcome email with password setup link
        WaitlistMailer.welcome(identity: identity, account: account).deliver_later

        # Remove from waitlist
        @waitlist_entry.destroy!
      end

      redirect_to admin_waitlist_entries_path, notice: "#{@waitlist_entry.name} has been approved. A welcome email has been sent."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_waitlist_entries_path, alert: "Failed to approve: #{e.message}"
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
