class PagesController < ApplicationController
  layout "static"

  before_action :set_body_class

  def set_body_class
    @body_class = "#{ params[:controller] }-#{ params[:action] }"
  end
end
