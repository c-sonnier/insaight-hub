require "test_helper"

class NotifyCommentJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @insight_item = insight_items(:one)   # owned by owner_user
    @account = accounts(:default)
  end

  test "notifies only the insight owner" do
    engagement = engagements(:two)   # comment by member_user on owner_user's insight

    assert_difference "Notification.count", 1 do
      NotifyCommentJob.perform_now(engagement_id: engagement.id, account_id: @account.id, actor_id: engagement.user_id)
    end

    notification = Notification.order(:id).last
    assert_equal users(:owner_user), notification.recipient
    assert_equal users(:member_user), notification.actor
    assert_equal engagement.engageable, notification.comment
    assert notification.comment_created?
  end

  test "does nothing when the commenter is the insight owner" do
    engagement = engagements(:one)   # comment by owner_user on their own insight

    assert_no_difference "Notification.count" do
      assert_no_enqueued_emails do
        NotifyCommentJob.perform_now(engagement_id: engagement.id, account_id: @account.id, actor_id: engagement.user_id)
      end
    end
  end

  test "skips email when owner disabled it" do
    identities(:owner).update!(email_notifications: false)
    engagement = engagements(:two)

    assert_no_enqueued_emails do
      NotifyCommentJob.perform_now(engagement_id: engagement.id, account_id: @account.id, actor_id: engagement.user_id)
    end
  end
end
