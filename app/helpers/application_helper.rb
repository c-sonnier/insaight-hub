module ApplicationHelper
  include Pagy::Frontend
  include AccountRoutingHelper

  def user_avatar(user, size: "w-10", css_class: "")
    avatar_classes = "avatar #{css_class}".strip

    content_tag :div, class: avatar_classes do
      content_tag :div, class: "#{size} rounded-full" do
        if user&.avatar&.attached?
          image_tag user.avatar.variant(resize_to_limit: [200, 200]), alt: user.name, class: "rounded-full"
        else
          image_tag "default_avatar.svg", alt: user&.name, class: "rounded-full"
        end
      end
    end
  end

  def user_avatar_or_initials(user, size: "w-10", css_class: "")
    avatar_classes = "avatar placeholder #{css_class}".strip

    content_tag :div, class: avatar_classes do
      if user&.avatar&.attached?
        content_tag :div, class: "#{size} rounded-full" do
          image_tag user.avatar.variant(resize_to_limit: [200, 200]), alt: user.name, class: "rounded-full"
        end
      else
        content_tag :div, class: "bg-neutral text-neutral-content #{size} rounded-full" do
          content_tag :span, user&.name&.first&.upcase || ""
        end
      end
    end
  end
end
