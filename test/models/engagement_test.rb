# frozen_string_literal: true

require "test_helper"

class EngagementTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @insight_item = insight_items(:one)
  end

  test "valid engagement with comment" do
    comment = Comment.new(body: "Test comment")
    engagement = Engagement.new(
      insight_item: @insight_item,
      user: @user,
      engageable: comment
    )

    assert engagement.valid?
  end

  test "requires insight_item" do
    comment = Comment.new(body: "Test comment")
    engagement = Engagement.new(
      user: @user,
      engageable: comment
    )

    assert_not engagement.valid?
    assert_includes engagement.errors[:insight_item], "must exist"
  end

  test "requires user" do
    comment = Comment.new(body: "Test comment")
    engagement = Engagement.new(
      insight_item: @insight_item,
      engageable: comment
    )

    assert_not engagement.valid?
    assert_includes engagement.errors[:user], "must exist"
  end

  test "recent scope orders by created_at desc" do
    comment1 = Comment.create!(body: "First comment")
    engagement1 = Engagement.create!(
      insight_item: @insight_item,
      user: @user,
      engageable: comment1,
      created_at: 2.days.ago
    )

    comment2 = Comment.create!(body: "Second comment")
    engagement2 = Engagement.create!(
      insight_item: @insight_item,
      user: @user,
      engageable: comment2,
      created_at: 1.day.ago
    )

    recent = Engagement.recent
    assert_equal engagement2, recent.first
    assert_equal engagement1, recent.second
  end

  test "comments scope filters by engageable_type" do
    comment = Comment.create!(body: "A comment")
    engagement = Engagement.create!(
      insight_item: @insight_item,
      user: @user,
      engageable: comment
    )

    assert_includes Engagement.comments, engagement
  end

  test "delegates engageable methods" do
    comment = Comment.create!(body: "Test comment")
    engagement = Engagement.create!(
      insight_item: @insight_item,
      user: @user,
      engageable: comment
    )

    assert engagement.comment?
    assert_equal comment, engagement.comment
  end
end

