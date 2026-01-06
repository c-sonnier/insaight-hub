class AccountSetupController < ApplicationController
  allow_unauthenticated_access
  before_action :set_identity_by_token

  def edit
  end

  def update
    if @identity.update(params.permit(:password, :password_confirmation))
      redirect_to new_session_path, notice: "Your account is ready. Please sign in."
    else
      redirect_to edit_account_setup_path(params[:token]), alert: "Passwords did not match."
    end
  end

  private

  def set_identity_by_token
    @identity = Identity.find_by_token_for!(:account_setup, params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to root_path, alert: "Setup link is invalid or has expired."
  end
end
