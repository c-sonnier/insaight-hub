class OnboardingController < ApplicationController
  allow_unauthenticated_access

  before_action :require_no_identities

  def new
    @identity = Identity.new
  end

  def create
    ActiveRecord::Base.transaction do
      # Create the super admin identity
      @identity = Identity.new(identity_params)
      @identity.admin = true

      if @identity.save
        # Create the default account
        @account = Account.create!(name: account_name)

        # Create the owner membership
        @user = User.create!(
          identity: @identity,
          account: @account,
          role: :owner
        )

        start_new_session_for(@identity)
        redirect_to "/#{@account.external_id}/dashboard", notice: "Welcome to insAIght Hub! Your admin account has been created."
      else
        render :new, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    @identity.errors.add(:base, e.message)
    render :new, status: :unprocessable_entity
  end

  private

  def require_no_identities
    redirect_to root_path if Identity.exists?
  end

  def identity_params
    params.require(:user).permit(:name, :email_address, :password, :password_confirmation)
  end

  def account_name
    params.dig(:user, :account_name).presence || "My Organization"
  end
end
