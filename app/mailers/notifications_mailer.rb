class NotificationsMailer < ApplicationMailer
  helper_method :insight_url, :preferences_url

  def insight_published(recipient:, actor:, insight_item:, comment: nil)
    @recipient = recipient
    @actor = actor
    @insight_item = insight_item

    mail(
      to: recipient.email_address,
      subject: "#{actor_name} published \"#{insight_item.title}\" in #{insight_item.account.name}"
    )
  end

  def insight_updated(recipient:, actor:, insight_item:, comment: nil)
    @recipient = recipient
    @actor = actor
    @insight_item = insight_item

    mail(
      to: recipient.email_address,
      subject: "#{actor_name} updated \"#{insight_item.title}\" in #{insight_item.account.name}"
    )
  end

  def comment_created(recipient:, actor:, insight_item:, comment:)
    @recipient = recipient
    @actor = actor
    @insight_item = insight_item
    @comment = comment

    mail(
      to: recipient.email_address,
      subject: "#{actor_name} commented on \"#{insight_item.title}\""
    )
  end

  private

  def actor_name
    @actor&.name || "Someone"
  end
  helper_method :actor_name

  # Account scoping lives in the URL path prefix (middleware), so mailer links
  # must set script_name explicitly.
  def insight_url
    insight_item_url(@insight_item, script_name: "/#{@insight_item.account.external_id}")
  end

  def preferences_url
    edit_profile_url(script_name: "/#{@insight_item.account.external_id}")
  end
end
