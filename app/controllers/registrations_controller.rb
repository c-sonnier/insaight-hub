class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  before_action :set_invite
  before_action :verify_invite_available

  def new
    @identity = Identity.new(email_address: @invite.email)
    @existing_identity = Identity.find_by(email_address: @invite.email&.downcase)
  end

  def create
    email = @invite.email.presence || identity_params[:email_address]

    ActiveRecord::Base.transaction do
      # Check if identity already exists
      @identity = Identity.find_by(email_address: email&.downcase)

      if @identity
        # Existing identity - just add membership to the invite's account
        # Verify password if this is an existing identity
        unless @identity.authenticate(identity_params[:password])
          @identity = Identity.new(email_address: email)
          @identity.errors.add(:password, "is invalid")
          return render :new, status: :unprocessable_entity
        end
      else
        # New identity
        @identity = Identity.new(identity_params)
        @identity.email_address = email if @invite.email.present?

        unless @identity.save
          return render :new, status: :unprocessable_entity
        end
      end

      # Create membership in the invite's account
      @user = User.create!(
        identity: @identity,
        account: @invite.account,
        role: :member
      )

      @invite.use!(@user)
      start_new_session_for(@identity)
      redirect_to "/#{@invite.account.external_id}/dashboard", notice: "Welcome! You've joined #{@invite.account.name}."
    end
  rescue ActiveRecord::RecordInvalid => e
    @identity ||= Identity.new(email_address: email)
    @identity.errors.add(:base, e.message)
    render :new, status: :unprocessable_entity
  end

  private

  def set_invite
    @invite = Invite.find_by(token: params[:token])
  end

  def verify_invite_available
    if @invite.nil?
      redirect_to new_session_path, alert: "Invalid invite link."
    elsif !@invite.available?
      if @invite.used_at.present?
        redirect_to new_session_path, alert: "This invite has already been used."
      else
        redirect_to new_session_path, alert: "This invite has expired."
      end
    end
  end

  def identity_params
    params.require(:user).permit(:name, :email_address, :password, :password_confirmation)
  end
end
