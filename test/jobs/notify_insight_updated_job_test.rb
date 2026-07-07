require "test_helper"

class NotifyInsightUpdatedJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @insight_item = insight_items(:one)
    @actor = users(:owner_user)
  end

  test "creates a notification for every account member except the actor" do
    assert_difference "Notification.count", 2 do
      NotifyInsightUpdatedJob.perform_now(insight_item_id: @insight_item.id, account_id: @insight_item.account_id, actor_id: @actor.id)
    end
  end

  test "does not stack unread updated notifications for the same insight" do
    NotifyInsightUpdatedJob.perform_now(insight_item_id: @insight_item.id, account_id: @insight_item.account_id, actor_id: @actor.id)

    assert_no_difference "Notification.count" do
      NotifyInsightUpdatedJob.perform_now(insight_item_id: @insight_item.id, account_id: @insight_item.account_id, actor_id: @actor.id)
    end
  end

  test "debounces update emails within the window" do
    assert_enqueued_emails 2 do
      NotifyInsightUpdatedJob.perform_now(insight_item_id: @insight_item.id, account_id: @insight_item.account_id, actor_id: @actor.id)
    end
    assert_not_nil @insight_item.reload.update_emails_sent_at

    Notification.where(action: :insight_updated).each(&:read!)
    assert_no_enqueued_emails do
      NotifyInsightUpdatedJob.perform_now(insight_item_id: @insight_item.id, account_id: @insight_item.account_id, actor_id: @actor.id)
    end
  end

  test "sends update emails again after the debounce window" do
    @insight_item.update_column(:update_emails_sent_at, 1.hour.ago)

    assert_enqueued_emails 2 do
      NotifyInsightUpdatedJob.perform_now(insight_item_id: @insight_item.id, account_id: @insight_item.account_id, actor_id: @actor.id)
    end
  end

  test "creates a fresh notification once the previous one is read" do
    NotifyInsightUpdatedJob.perform_now(insight_item_id: @insight_item.id, account_id: @insight_item.account_id, actor_id: @actor.id)
    Notification.where(action: :insight_updated).each(&:read!)

    assert_difference "Notification.count", 2 do
      NotifyInsightUpdatedJob.perform_now(insight_item_id: @insight_item.id, account_id: @insight_item.account_id, actor_id: @actor.id)
    end
  end
end
