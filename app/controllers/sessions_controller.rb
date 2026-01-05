class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  before_action :redirect_to_onboarding_if_no_users, only: %i[ new create ]

  def new
  end

  def create
    if identity = Identity.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for identity
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end

  private

  def redirect_to_onboarding_if_no_users
    redirect_to onboarding_path if Identity.none?
  end
end
