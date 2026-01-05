class WaitlistController < ApplicationController
  allow_unauthenticated_access

  def new
    @waitlist_entry = WaitlistEntry.new
  end

  def create
    @waitlist_entry = WaitlistEntry.new(waitlist_params)

    if @waitlist_entry.save
      redirect_to waitlist_thank_you_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def thank_you
  end

  private

  def waitlist_params
    params.require(:waitlist_entry).permit(:email)
  end
end
