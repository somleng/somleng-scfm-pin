class Dashboard::BaseController < ApplicationController
  before_action :authenticate_user!

  def current_account
    current_user.account
  end

  private

  def authorize_admin!
    deny_access! unless current_user.is_admin?
  end

  def deny_access!
    head(:unauthorized)
  end
end
