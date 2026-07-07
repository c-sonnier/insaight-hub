# Concern for notification jobs that deliver to one or more recipients
# across both channels (in-app and email), honoring each recipient's
# identity-level preferences independently.
module NotifiableFanOut
  extend ActiveSupport::Concern

  private

  def deliver(recipients:, action:, insight_item:, actor:, comment: nil, email: true)
    recipients.each do |recipient|
      identity = recipient.identity

      if identity.in_app_notifications?
        create_notification(recipient: recipient, action: action, insight_item: insight_item, actor: actor, comment: comment)
      end

      if email && identity.email_notifications?
        NotificationsMailer.public_send(
          action,
          recipient: recipient,
          actor: actor,
          insight_item: insight_item,
          comment: comment
        ).deliver_later
      end
    end
  end

  def create_notification(recipient:, action:, insight_item:, actor:, comment: nil)
    # Idempotent: a retried job or a double callback shouldn't stack duplicate
    # unread notifications. A comment scopes the guard to that comment so each
    # distinct comment still notifies.
    return if recipient.notifications.unread.exists?(action: action, insight_item: insight_item, comment: comment)

    Notification.create!(
      recipient: recipient,
      actor: actor,
      account: insight_item.account,
      insight_item: insight_item,
      comment: comment,
      action: action
    )
  end
end
