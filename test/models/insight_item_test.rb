require "test_helper"

class InsightItemTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "publish! enqueues published notification job only" do
    insight = insight_items(:two)

    assert_enqueued_with(job: NotifyInsightPublishedJob, args: [ { insight_item_id: insight.id, account_id: insight.account_id, actor_id: insight.user_id } ]) do
      insight.publish!
    end
    assert_no_enqueued_jobs(only: NotifyInsightUpdatedJob)
  end

  test "updating published insight content enqueues updated notification job" do
    insight = insight_items(:one)

    assert_enqueued_with(job: NotifyInsightUpdatedJob, args: [ { insight_item_id: insight.id, account_id: insight.account_id, actor_id: insight.user_id } ]) do
      insight.update!(title: "New Title")
    end
  end

  test "updating draft insight enqueues no notification jobs" do
    insight = insight_items(:two)

    assert_no_enqueued_jobs(only: [ NotifyInsightPublishedJob, NotifyInsightUpdatedJob ]) do
      insight.update!(title: "Draft Title")
    end
  end

  test "non-content update to published insight enqueues no notification jobs" do
    insight = insight_items(:one)

    assert_no_enqueued_jobs(only: [ NotifyInsightPublishedJob, NotifyInsightUpdatedJob ]) do
      insight.update!(thumbnail_generating: true)
    end
  end

  test "unpublish! enqueues no notification jobs" do
    insight = insight_items(:one)

    assert_no_enqueued_jobs(only: [ NotifyInsightPublishedJob, NotifyInsightUpdatedJob ]) do
      insight.unpublish!
    end
  end

  test "same slug is allowed across different accounts" do
    existing = insight_items(:one)
    other = insight_items(:other_account_insight)

    other.update!(slug: existing.slug)

    assert_equal existing.slug, other.reload.slug
    refute_equal existing.account_id, other.account_id
  end

  test "duplicate slug within the same account is rejected" do
    existing = insight_items(:one)
    dup = InsightItem.new(
      account: existing.account,
      user: existing.user,
      title: "Dup",
      slug: existing.slug,
      audience: :developer,
      status: :draft
    )

    refute dup.valid?
    assert_includes dup.errors[:slug], "has already been taken"
  end

  test "files_as_markdown excludes CSS and JS files" do
    insight = insight_items(:one)
    result = insight.files_as_markdown
    filenames = result.map { |f| f[:filename] }
    assert_includes filenames, "index.html"
    refute_includes filenames, "styles.css"
    refute_includes filenames, "app.js"
  end

  test "files_as_markdown converts HTML content_type to text/markdown" do
    insight = insight_items(:one)
    result = insight.files_as_markdown
    html_result = result.find { |f| f[:filename] == "index.html" }
    assert_equal "text/markdown", html_result[:content_type]
  end

  test "files_as_markdown preserves markdown file content_type" do
    insight = insight_items(:two)
    result = insight.files_as_markdown
    md_result = result.find { |f| f[:filename] == "readme.md" }
    assert_equal "text/markdown", md_result[:content_type]
  end

  test "files_as_markdown preserves JSON file content_type" do
    insight = insight_items(:two)
    result = insight.files_as_markdown
    json_result = result.find { |f| f[:filename] == "data.json" }
    assert_equal "application/json", json_result[:content_type]
  end

  test "files_as_markdown returns converted HTML as markdown" do
    insight = insight_items(:one)
    result = insight.files_as_markdown
    html_result = result.find { |f| f[:filename] == "index.html" }
    assert_includes html_result[:content], "Hello World"
    refute_includes html_result[:content], "<html>"
  end

  test "files_as_markdown wraps JSON content in fenced code block" do
    insight = insight_items(:two)
    result = insight.files_as_markdown
    json_result = result.find { |f| f[:filename] == "data.json" }
    assert json_result[:content].start_with?("```json\n")
  end

  test "files_as_markdown places entry file first" do
    insight = insight_items(:one)
    insight.update!(entry_file: "index.html")
    result = insight.files_as_markdown
    assert_equal "index.html", result.first[:filename] if result.any?
  end

  test "files_as_markdown returns empty array when only CSS/JS files" do
    insight = insight_items(:one)
    insight.insight_item_files.where.not(content_type: [ "text/css", "text/javascript" ]).destroy_all
    result = insight.files_as_markdown
    assert_equal [], result
  end

  test "edited_since_publish? true when updated well after publish" do
    insight = insight_items(:one)
    insight.published_at = 2.days.ago
    insight.updated_at = 1.hour.ago
    assert insight.edited_since_publish?
  end

  test "edited_since_publish? false right after publish" do
    insight = insight_items(:one)
    now = Time.current
    insight.published_at = now
    insight.updated_at = now + 30.seconds
    refute insight.edited_since_publish?
  end

  test "edited_since_publish? false when never published" do
    insight = insight_items(:two)
    assert_nil insight.published_at
    refute insight.edited_since_publish?
  end
end
