class InvitesMailer < ApplicationMailer
  def invite_email
    @invite = params[:invite]
    @account = @invite.account
    @inviter = @invite.created_by

    mail(
      to: @invite.email,
      subject: "You've been invited to join #{@account.name} on insAIght Hub"
    )
  end
end
