require "test_helper"

class NotifyInsightPublishedJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @insight_item = insight_items(:one)
    @actor = users(:owner_user)
    # Start from a clean slate: notifications are now idempotent, so a
    # pre-existing unread notification for this insight would be deduped.
    Notification.where(insight_item: @insight_item).delete_all
  end

  test "creates a notification for every account member except the actor" do
    assert_difference "Notification.count", 2 do
      NotifyInsightPublishedJob.perform_now(insight_item_id: @insight_item.id, account_id: @insight_item.account_id, actor_id: @actor.id)
    end

    recipients = Notification.where(action: :insight_published, insight_item: @insight_item, actor: @actor).pluck(:recipient_id)
    assert_includes recipients, users(:admin_user).id
    assert_includes recipients, users(:member_user).id
    refute_includes recipients, @actor.id
  end

  test "enqueues an email for every account member except the actor" do
    assert_enqueued_emails 2 do
      NotifyInsightPublishedJob.perform_now(insight_item_id: @insight_item.id, account_id: @insight_item.account_id, actor_id: @actor.id)
    end
  end

  test "skips in-app notification when recipient disabled it" do
    identities(:member).update!(in_app_notifications: false)

    assert_difference "Notification.count", 1 do
      NotifyInsightPublishedJob.perform_now(insight_item_id: @insight_item.id, account_id: @insight_item.account_id, actor_id: @actor.id)
    end
    assert_equal users(:admin_user), Notification.order(:id).last.recipient
  end

  test "skips email when recipient disabled it" do
    identities(:member).update!(email_notifications: false)

    assert_enqueued_emails 1 do
      NotifyInsightPublishedJob.perform_now(insight_item_id: @insight_item.id, account_id: @insight_item.account_id, actor_id: @actor.id)
    end
  end

  test "does nothing when insight is no longer published" do
    @insight_item.update_column(:status, "draft")

    assert_no_difference "Notification.count" do
      NotifyInsightPublishedJob.perform_now(insight_item_id: @insight_item.id, account_id: @insight_item.account_id, actor_id: @actor.id)
    end
  end
end
