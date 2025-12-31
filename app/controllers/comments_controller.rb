# frozen_string_literal: true

class CommentsController < ApplicationController
  include Authentication
  include ActionView::RecordIdentifier

  before_action :set_insight_item
  before_action :set_comment, only: [:update, :destroy]
  before_action :authorize_comment!, only: [:update, :destroy]

  def create
    @comment = Comment.new(comment_params)
    @engagement = @insight_item.engagements.build(
      user: Current.user,
      engageable: @comment
    )

    respond_to do |format|
      if @engagement.save
        format.turbo_stream
        format.html { redirect_to @insight_item, notice: "Comment added." }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_comment_form",
            partial: "comments/form",
            locals: { insight_item: @insight_item, comment: @comment }
          )
        end
        format.html { redirect_to @insight_item, alert: "Could not add comment." }
      end
    end
  end

  def update
    respond_to do |format|
      if @comment.update(comment_params)
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@comment.engagement),
            partial: "comments/comment",
            locals: { comment: @comment, engagement: @comment.engagement }
          )
        end
        format.html { redirect_to @insight_item, notice: "Comment updated." }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "edit_comment_#{@comment.id}",
            partial: "comments/edit_form",
            locals: { insight_item: @insight_item, comment: @comment }
          )
        end
        format.html { redirect_to @insight_item, alert: "Could not update comment." }
      end
    end
  end

  def destroy
    @engagement = @comment.engagement
    @engagement.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove(dom_id(@engagement))
      end
      format.html { redirect_to @insight_item, notice: "Comment deleted." }
    end
  end

  private

  def set_insight_item
    @insight_item = InsightItem.find_by!(slug: params[:insight_item_id])
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def authorize_comment!
    unless can_modify_comment?(@comment)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("flash", partial: "shared/flash",
            locals: { message: "You are not authorized to modify this comment.", type: :alert })
        end
        format.html { redirect_to @insight_item, alert: "You are not authorized to modify this comment." }
      end
    end
  end

  def can_modify_comment?(comment)
    Current.user == comment.user || Current.user.admin?
  end

  def comment_params
    params.require(:comment).permit(:body, :parent_id)
  end
end

