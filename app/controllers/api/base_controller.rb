class Api::BaseController < ApplicationController
  before_action :verify_requested_format!

  def create
    build_resource
    setup_resource
    save_resource
    respond_with_create_resource
  end

  def show
    find_resource
    respond_with_show_resource
  end

  private

  def respond_with_show_resource
    respond_with(resource)
  end

  def find_resource
    @resource = association_chain.find(params[:id])
  end

  def build_resource
    @resource = association_chain.new(permitted_params)
  end

  def setup_resource
  end

  def save_resource
    resource.save
  end

  def resource
    @resource
  end

  def resources
    @resources
  end
end
