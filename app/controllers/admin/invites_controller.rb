module Admin
  class InvitesController < BaseController
    def index
      @invites = Invite.includes(:created_by, :used_by).order(created_at: :desc)
    end

    def new
      @invite = Invite.new
    end

    def create
      @invite = Invite.new(invite_params)
      @invite.created_by = Current.user

      if @invite.save
        redirect_to admin_invites_path, notice: "Invite created. Share this link: #{register_url(token: @invite.token)}"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @invite = Invite.find(params[:id])

      if @invite.used_at.present?
        redirect_to admin_invites_path, alert: "Cannot delete an invite that has already been used."
      else
        @invite.destroy
        redirect_to admin_invites_path, notice: "Invite was successfully revoked."
      end
    end

    private

    def invite_params
      params.require(:invite).permit(:email, :expires_at)
    end
  end
end
