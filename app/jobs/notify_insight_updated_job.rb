class NotifyInsightUpdatedJob < ApplicationJob
  include AccountAware
  include NotifiableFanOut

  queue_as :default

  # Rapid successive edits shouldn't email the whole organization each time
  EMAIL_DEBOUNCE_WINDOW = 30.minutes

  def perform(insight_item_id:, account_id:, actor_id:)
    with_account_context(account_id) do
      insight_item = InsightItem.find_by(id: insight_item_id)
      return unless insight_item&.published?

      actor = User.find_by(id: actor_id)
      recipients = insight_item.account.users.where.not(id: actor_id).includes(:identity)
      send_emails = insight_item.update_emails_sent_at.nil? || insight_item.update_emails_sent_at < EMAIL_DEBOUNCE_WINDOW.ago

      # Stamp the debounce window *before* delivering so a crash mid-fan-out and
      # subsequent retry can't re-email the whole organization.
      insight_item.update_column(:update_emails_sent_at, Time.current) if send_emails

      deliver(recipients: recipients, action: :insight_updated, insight_item: insight_item, actor: actor, email: send_emails)
    end
  end
end
