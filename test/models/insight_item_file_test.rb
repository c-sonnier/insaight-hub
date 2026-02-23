require "test_helper"

class InsightItemFileTest < ActiveSupport::TestCase
  test "markdown_convertible? returns true for HTML files" do
    file = insight_item_files(:html_file)
    assert file.markdown_convertible?
  end

  test "markdown_convertible? returns true for markdown files" do
    file = insight_item_files(:markdown_file)
    assert file.markdown_convertible?
  end

  test "markdown_convertible? returns true for JSON files" do
    file = insight_item_files(:json_file)
    assert file.markdown_convertible?
  end

  test "markdown_convertible? returns false for CSS files" do
    file = insight_item_files(:css_file)
    refute file.markdown_convertible?
  end

  test "markdown_convertible? returns false for JS files" do
    file = insight_item_files(:js_file)
    refute file.markdown_convertible?
  end

  test "to_markdown converts HTML to markdown" do
    file = insight_item_files(:html_file)
    result = file.to_markdown
    assert_includes result, "Hello World"
    assert_includes result, "This is a test."
    refute_includes result, "<html>"
  end

  test "to_markdown passes through markdown content" do
    file = insight_item_files(:markdown_file)
    assert_equal file.content, file.to_markdown
  end

  test "to_markdown wraps JSON in fenced code block" do
    file = insight_item_files(:json_file)
    result = file.to_markdown
    assert result.start_with?("```json\n")
    assert result.end_with?("\n```")
    assert_includes result, '"key": "value"'
  end

  test "to_markdown returns nil for CSS files" do
    file = insight_item_files(:css_file)
    assert_nil file.to_markdown
  end

  test "to_markdown returns nil for JS files" do
    file = insight_item_files(:js_file)
    assert_nil file.to_markdown
  end
end
