class PasswordsMailer < ApplicationMailer
  def reset(identity)
    @identity = identity
    mail subject: "Reset your password", to: identity.email_address
  end
end
