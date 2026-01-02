module MetaTagsHelper
  # Default site configuration
  SITE_NAME = "insAIght Hub".freeze
  DEFAULT_DESCRIPTION = "Transform scattered AI output into shared understanding — structured, searchable, and easy to act on.".freeze
  DEFAULT_KEYWORDS = "AI insights, knowledge management, team collaboration, AI documentation, MCP integration".freeze

  # Generate all meta tags for the current page
  def meta_tags
    safe_join([
      basic_meta_tags,
      open_graph_tags,
      twitter_card_tags
    ].flatten.compact, "\n    ")
  end

  # Content helpers for setting page-specific meta data
  def page_title(title = nil)
    if title.present?
      content_for(:page_title, title)
      content_for(:title, "#{title} | #{SITE_NAME}")
    end
  end

  def page_description(description)
    content_for(:page_description, description) if description.present?
  end

  def page_image(image_url)
    content_for(:page_image, image_url) if image_url.present?
  end

  def page_url(url)
    content_for(:page_url, url) if url.present?
  end

  def page_type(type)
    content_for(:page_type, type) if type.present?
  end

  def page_keywords(keywords)
    content_for(:page_keywords, keywords) if keywords.present?
  end

  private

  def current_page_title
    content_for(:page_title).presence || SITE_NAME
  end

  def current_page_description
    content_for(:page_description).presence || DEFAULT_DESCRIPTION
  end

  def current_page_image
    content_for(:page_image).presence || default_og_image_url
  end

  def current_page_url
    content_for(:page_url).presence || request.original_url
  end

  def current_page_type
    content_for(:page_type).presence || "website"
  end

  def current_page_keywords
    content_for(:page_keywords).presence || DEFAULT_KEYWORDS
  end

  def default_og_image_url
    # Use the branded OG image for social previews
    helpers_url_for("/og-image.png", only_path: false)
  end

  def helpers_url_for(path, options = {})
    if options[:only_path] == false
      "#{request.protocol}#{request.host_with_port}#{path}"
    else
      path
    end
  end

  def basic_meta_tags
    [
      tag.meta(name: "description", content: current_page_description),
      tag.meta(name: "keywords", content: current_page_keywords),
      tag.meta(name: "author", content: SITE_NAME),
      tag.meta(name: "robots", content: "index, follow"),
      tag.meta(name: "theme-color", content: "#183C67"),
      tag.link(rel: "canonical", href: current_page_url)
    ]
  end

  def open_graph_tags
    [
      # Basic OG tags
      tag.meta(property: "og:site_name", content: SITE_NAME),
      tag.meta(property: "og:title", content: current_page_title),
      tag.meta(property: "og:description", content: current_page_description),
      tag.meta(property: "og:url", content: current_page_url),
      tag.meta(property: "og:type", content: current_page_type),
      tag.meta(property: "og:locale", content: "en_US"),

      # Image tags
      tag.meta(property: "og:image", content: current_page_image),
      tag.meta(property: "og:image:alt", content: current_page_title),
      tag.meta(property: "og:image:width", content: "1200"),
      tag.meta(property: "og:image:height", content: "630"),
      tag.meta(property: "og:image:type", content: "image/png")
    ]
  end

  def twitter_card_tags
    [
      tag.meta(name: "twitter:card", content: "summary_large_image"),
      tag.meta(name: "twitter:title", content: current_page_title),
      tag.meta(name: "twitter:description", content: current_page_description),
      tag.meta(name: "twitter:image", content: current_page_image),
      tag.meta(name: "twitter:image:alt", content: current_page_title)
    ]
  end
end

