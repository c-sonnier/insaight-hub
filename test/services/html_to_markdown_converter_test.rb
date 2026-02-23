require "test_helper"

class HtmlToMarkdownConverterTest < ActiveSupport::TestCase
  test "converts basic HTML to markdown" do
    html = "<h1>Title</h1><p>Paragraph text.</p>"
    result = HtmlToMarkdownConverter.convert(html)
    assert_includes result, "# Title"
    assert_includes result, "Paragraph text."
  end

  test "strips style tags and contents" do
    html = "<style>body { color: red; }</style><p>Visible text</p>"
    result = HtmlToMarkdownConverter.convert(html)
    assert_includes result, "Visible text"
    refute_includes result, "color: red"
    refute_includes result, "<style>"
  end

  test "strips script tags and contents" do
    html = "<p>Before</p><script>alert('xss');</script><p>After</p>"
    result = HtmlToMarkdownConverter.convert(html)
    assert_includes result, "Before"
    assert_includes result, "After"
    refute_includes result, "alert"
    refute_includes result, "<script>"
  end

  test "strips link stylesheet tags" do
    html = '<link rel="stylesheet" href="styles.css"><p>Content</p>'
    result = HtmlToMarkdownConverter.convert(html)
    assert_includes result, "Content"
    refute_includes result, "stylesheet"
  end

  test "replaces base64 images with placeholder" do
    html = '<img src="data:image/png;base64,iVBORw0KGgo=" alt="screenshot">'
    result = HtmlToMarkdownConverter.convert(html)
    assert_includes result, "image-removed"
    refute_includes result, "iVBORw0KGgo"
  end

  test "preserves normal image URLs" do
    html = '<img src="https://example.com/photo.jpg" alt="photo">'
    result = HtmlToMarkdownConverter.convert(html)
    assert_includes result, "https://example.com/photo.jpg"
  end

  test "replaces inline SVGs with placeholder" do
    html = '<p>Before</p><svg xmlns="http://www.w3.org/2000/svg"><circle cx="50" cy="50" r="40"/></svg><p>After</p>'
    result = HtmlToMarkdownConverter.convert(html)
    assert_includes result, "[SVG graphic]"
    refute_includes result, "<svg"
    refute_includes result, "<circle"
  end

  test "converts tables to markdown" do
    html = "<table><tr><th>Name</th><th>Age</th></tr><tr><td>Alice</td><td>30</td></tr></table>"
    result = HtmlToMarkdownConverter.convert(html)
    assert_includes result, "Name"
    assert_includes result, "Alice"
  end

  test "converts links to markdown" do
    html = '<a href="https://example.com">Click here</a>'
    result = HtmlToMarkdownConverter.convert(html)
    assert_includes result, "[Click here](https://example.com)"
  end

  test "handles full HTML document with head and body" do
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Page Title</title>
        <style>body { margin: 0; }</style>
        <script>var x = 1;</script>
      </head>
      <body>
        <h1>Main Heading</h1>
        <p>Body content here.</p>
      </body>
      </html>
    HTML
    result = HtmlToMarkdownConverter.convert(html)
    assert_includes result, "# Main Heading"
    assert_includes result, "Body content here."
    refute_includes result, "margin: 0"
    refute_includes result, "var x = 1"
  end

  test "handles empty HTML" do
    result = HtmlToMarkdownConverter.convert("")
    assert_equal "", result
  end
end
