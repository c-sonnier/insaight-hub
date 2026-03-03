module Admin
  class AccountsController < BaseController
    def edit
      @account = current_account
    end

    def update
      @account = current_account

      if @account.update(account_params)
        redirect_to admin_organization_path, notice: "Organization name was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def account_params
      params.require(:account).permit(:name)
    end
  end
end
