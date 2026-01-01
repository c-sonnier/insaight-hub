# frozen_string_literal: true

require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @insight_item = insight_items(:one)
  end

  test "valid comment" do
    comment = Comment.new(body: "This is a valid comment")
    assert comment.valid?
  end

  test "requires body" do
    comment = Comment.new(body: nil)
    assert_not comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "body cannot exceed 5000 characters" do
    comment = Comment.new(body: "a" * 5001)
    assert_not comment.valid?
    assert_includes comment.errors[:body], "is too long (maximum is 5000 characters)"
  end

  test "can be a reply to another comment" do
    parent = Comment.create!(body: "Parent comment")
    reply = Comment.new(body: "Reply comment", parent: parent)

    assert reply.valid?
    assert reply.reply?
    assert_equal parent, reply.parent
  end

  test "root comment is not a reply" do
    comment = Comment.new(body: "Root comment")
    assert_not comment.reply?
  end

  test "has_replies? returns true when replies exist" do
    parent = Comment.create!(body: "Parent comment")
    Comment.create!(body: "Reply comment", parent: parent)

    assert parent.has_replies?
  end

  test "has_replies? returns false when no replies" do
    comment = Comment.create!(body: "Lonely comment")
    assert_not comment.has_replies?
  end

  test "depth is 0 for root comments" do
    comment = Comment.new(body: "Root comment")
    assert_equal 0, comment.depth
  end

  test "depth is 1 for first-level replies" do
    parent = Comment.create!(body: "Parent")
    reply = Comment.new(body: "Reply", parent: parent)
    assert_equal 1, reply.depth
  end

  test "depth is 2 for nested replies" do
    grandparent = Comment.create!(body: "Grandparent")
    parent = Comment.create!(body: "Parent", parent: grandparent)
    child = Comment.new(body: "Child", parent: parent)

    assert_equal 2, child.depth
  end

  test "destroying parent destroys replies" do
    parent = Comment.create!(body: "Parent")
    reply = Comment.create!(body: "Reply", parent: parent)

    assert_difference "Comment.count", -2 do
      parent.destroy
    end
  end

  test "includes Engageable concern" do
    assert Comment.include?(Engageable)
  end

  test "root_comments scope excludes replies" do
    parent = Comment.create!(body: "Parent")
    Comment.create!(body: "Reply", parent: parent)

    root_comments = Comment.root_comments
    assert_includes root_comments, parent
    assert_equal 1, root_comments.where(id: [parent.id, parent.replies.first.id]).count
  end
end

