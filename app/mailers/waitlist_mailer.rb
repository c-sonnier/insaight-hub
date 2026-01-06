class WaitlistMailer < ApplicationMailer
  def welcome(identity:, account:)
    @identity = identity
    @account = account

    mail(
      to: identity.email_address,
      subject: "Welcome to insAIght Hub - Set up your account"
    )
  end
end
