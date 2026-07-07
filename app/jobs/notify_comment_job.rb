class NotifyCommentJob < ApplicationJob
  include AccountAware
  include NotifiableFanOut

  queue_as :default

  def perform(engagement_id:, account_id:, actor_id:)
    with_account_context(account_id) do
      engagement = Engagement.find_by(id: engagement_id)
      return unless engagement

      insight_item = engagement.insight_item
      owner = insight_item.user
      return if owner.nil? || owner.id == actor_id

      actor = User.find_by(id: actor_id)

      deliver(recipients: [ owner ], action: :comment_created, insight_item: insight_item, actor: actor, comment: engagement.engageable)
    end
  end
end
