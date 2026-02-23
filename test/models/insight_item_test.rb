require "test_helper"

class InsightItemTest < ActiveSupport::TestCase
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
    insight.insight_item_files.where.not(content_type: ["text/css", "text/javascript"]).destroy_all
    result = insight.files_as_markdown
    assert_equal [], result
  end
end
