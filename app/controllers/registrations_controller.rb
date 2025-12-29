class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  before_action :set_invite
  before_action :verify_invite_available

  def new
    @user = User.new(email_address: @invite.email)
  end

  def create
    @user = User.new(user_params)
    @user.email_address = @invite.email if @invite.email.present?

    if @user.save
      @invite.use!(@user)
      start_new_session_for(@user)
      redirect_to root_path, notice: "Welcome to Digest Hub! Your account has been created."
    else
      render :new, status: :unprocessable_entity
    end
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

  def user_params
    params.require(:user).permit(:name, :email_address, :password, :password_confirmation)
  end
end
