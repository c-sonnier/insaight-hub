module Admin
  class WaitlistEntriesController < BaseController
    def index
      @waitlist_entries = WaitlistEntry.order(created_at: :desc)
    end

    def destroy
      @waitlist_entry = WaitlistEntry.find(params[:id])
      @waitlist_entry.destroy
      redirect_to admin_waitlist_entries_path, notice: "Entry removed from waitlist."
    end
  end
end
