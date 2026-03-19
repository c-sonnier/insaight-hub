class AccountsController < ApplicationController
  def new
    @account = Account.new
  end

  def create
    ActiveRecord::Base.transaction do
      @account = Account.create!(name: params.require(:account).require(:name))
      User.create!(identity: Current.identity, account: @account, role: :owner)
      Current.identity.update_column(:last_account_id, @account.id)
    end

    redirect_to "/#{@account.external_id}/dashboard", notice: "Organization created."
  rescue ActiveRecord::RecordInvalid => e
    @account ||= Account.new
    @account.errors.add(:base, e.message) unless @account.errors.any?
    render :new, status: :unprocessable_entity
  end
end
