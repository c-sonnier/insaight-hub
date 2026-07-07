class NotificationsController < ApplicationController
  include AccountScoped

  def index
    @notifications = Current.user.notifications.recent.includes(:actor, :insight_item, :comment).limit(50)
  end

  def read
    notification = Current.user.notifications.find(params[:id])
    notification.read!
    redirect_to insight_item_path(notification.insight_item)
  end

  def read_all
    Current.user.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("notifications_badge", partial: "notifications/badge", locals: { user: Current.user }),
          turbo_stream.update("notifications_dropdown_list", partial: "notifications/list", locals: { user: Current.user })
        ]
      end
      format.html { redirect_to notifications_path }
    end
  end
end
