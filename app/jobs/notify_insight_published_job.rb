class NotifyInsightPublishedJob < ApplicationJob
  include AccountAware
  include NotifiableFanOut

  queue_as :default

  def perform(insight_item_id:, account_id:, actor_id:)
    with_account_context(account_id) do
      insight_item = InsightItem.find_by(id: insight_item_id)
      return unless insight_item&.published?

      actor = User.find_by(id: actor_id)
      recipients = insight_item.account.users.where.not(id: actor_id).includes(:identity)

      deliver(recipients: recipients, action: :insight_published, insight_item: insight_item, actor: actor)
    end
  end
end
