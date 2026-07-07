require "test_helper"

class NotificationsMailerTest < ActionMailer::TestCase
  setup do
    @recipient = users(:member_user)
    @actor = users(:owner_user)
    @insight_item = insight_items(:one)
  end

  test "insight_published" do
    email = NotificationsMailer.insight_published(recipient: @recipient, actor: @actor, insight_item: @insight_item)

    assert_equal [ @recipient.email_address ], email.to
    assert_includes email.subject, "published"
    assert_includes email.subject, @insight_item.title
    assert_includes email.html_part.body.to_s, "/#{@insight_item.account.external_id}/insight_items/#{@insight_item.slug}"
    assert_includes email.html_part.body.to_s, "/#{@insight_item.account.external_id}/profile/edit"
  end

  test "insight_updated" do
    email = NotificationsMailer.insight_updated(recipient: @recipient, actor: @actor, insight_item: @insight_item)

    assert_equal [ @recipient.email_address ], email.to
    assert_includes email.subject, "updated"
  end

  test "comment_created" do
    comment = comments(:one)
    email = NotificationsMailer.comment_created(recipient: users(:owner_user), actor: users(:member_user), insight_item: @insight_item, comment: comment)

    assert_equal [ users(:owner_user).email_address ], email.to
    assert_includes email.subject, "commented"
    assert_includes email.html_part.body.to_s, comment.body
  end

  test "actor falls back to Someone" do
    email = NotificationsMailer.insight_published(recipient: @recipient, actor: nil, insight_item: @insight_item)

    assert_includes email.subject, "Someone"
  end
end
