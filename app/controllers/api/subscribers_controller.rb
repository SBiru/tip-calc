class Api::SubscribersController < Api::ApiController
  skip_before_action :authenticate_user!
  skip_before_action :set_info

  respond_to :js

  def create
    @subscriber = Subscriber.new(subscriber_params)
    if @subscriber.save(subscriber_params)
      respond_to do |format|
        format.js 
      end
    end
  end

  protected

  def subscriber_params
    params.require(:subscriber).permit(:email)
  end
end