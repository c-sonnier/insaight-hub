module Admin
  class InvitesController < BaseController
    def index
      @invites = current_account.invites.includes(created_by: :identity, used_by: :identity).order(created_at: :desc)
    end

    def new
      @invite = current_account.invites.build
    end

    def create
      @invite = current_account.invites.build(invite_params)
      @invite.created_by = Current.user

      if @invite.save
        redirect_to admin_invites_path, notice: "Invite created. Share this link: #{register_url(token: @invite.token)}"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @invite = current_account.invites.find(params[:id])

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
