class HtmlToMarkdownConverter
  def self.convert(html)
    doc = Nokogiri::HTML.fragment(html)

    doc.css("style, script, link[rel='stylesheet']").remove

    doc.css("img").each do |img|
      src = img["src"].to_s
      img["src"] = "image-removed" if src.start_with?("data:image")
    end

    doc.css("svg").each { |svg| svg.replace("[SVG graphic]") }

    ReverseMarkdown.convert(doc.to_html, unknown_tags: :bypass).strip
  rescue => e
    raise ConversionError, "Failed to convert HTML to markdown: #{e.message}"
  end

  class ConversionError < StandardError; end
end
